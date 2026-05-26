//
//  WKRTCLiveKitMediaEngine.swift
//  TangSengDaoDao
//

import Foundation
import UIKit
import AVKit
@preconcurrency import LiveKit
import WuKongBase

/// LiveKit Swift SDK 桥接层。
/// Objective-C 业务层只依赖 WKRTCMediaEngine 协议，避免 Pods target 直接依赖 SPM。
@objcMembers
final class WKRTCLiveKitMediaEngine: NSObject, WKRTCMediaEngine, RoomDelegate, AVPictureInPictureControllerDelegate, @unchecked Sendable {
    // 1v1 音视频优先保证清晰度：关闭 adaptiveStream，避免首帧布局较小时被服务端压到 LOW 层。
    private lazy var room: Room = Room(
        delegate: self,
        roomOptions: RoomOptions(
            adaptiveStream: false,
            dynacast: true,
            suspendLocalVideoTracksInBackground: false
        )
    )
    private let cameraCaptureOptions = CameraCaptureOptions(position: .front, dimensions: .h1080_169, fps: 30)
    private let cameraPublishOptions = VideoPublishOptions(
        encoding: VideoEncoding(maxBitrate: 4_000_000, maxFps: 30),
        simulcast: false
    )
    private let localVideo = VideoView()
    private let remoteVideo = VideoView()
    private let pictureInPictureVideo = VideoView()
    private var participantVideoViews: [String: VideoView] = [:]
    private var participantIds: [String] = []
    private var participantStateMap: [String: WKRTCMediaParticipantState] = [:]
    private var stateHandler: ((WKRTCMediaEngineState, Error?) -> Void)?
    private var pictureInPictureController: AVPictureInPictureController?
    private var pictureInPictureContentViewController: UIViewController?
    private var pictureInPictureStartCompletion: (@Sendable (Error?) -> Void)?
    private var pictureInPictureStopCompletion: (() -> Void)?
    private weak var pictureInPictureSourceView: UIView?
    private var didConfigureMultitaskingCamera = false

    override init() {
        super.init()
        localVideo.backgroundColor = .black
        remoteVideo.backgroundColor = .black
        pictureInPictureVideo.backgroundColor = .black
        // 系统视频通话 PiP 要求内容视图使用 AVSampleBufferDisplayLayer 路径；
        // LiveKit 默认可能走 Metal，后台或 PiP 场景下容易出现 PiP 黑屏。
        pictureInPictureVideo.renderMode = .sampleBuffer
        pictureInPictureVideo.layoutMode = .fit
        pictureInPictureVideo.mirrorMode = .off
    }

    /// 使用后端返回的 LiveKit url/token 连接房间，token 不落盘、不打印日志。
    @nonobjc func connect(
        withURL url: String,
        token: String,
        audioEnabled: Bool,
        videoEnabled: Bool
    ) async throws {
        do {
            try await connectInternal(withURL: url, token: token, audioEnabled: audioEnabled, videoEnabled: videoEnabled)
            await MainActor.run {
                refreshParticipantsFromRoom(shouldNotify: true)
                stateHandler?(WKRTCMediaEngineState.connected, nil)
            }
        } catch {
            await MainActor.run {
                stateHandler?(WKRTCMediaEngineState.failed, error)
            }
            throw error
        }
    }

    /// ObjC 业务层调用的回调形式，签名必须与桥接后的 WKRTCMediaEngine 协议一致。
    func connect(
        withURL url: String,
        token: String,
        audioEnabled: Bool,
        videoEnabled: Bool,
        completion: @escaping @Sendable (Error?) -> Void
    ) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await connectInternal(withURL: url, token: token, audioEnabled: audioEnabled, videoEnabled: videoEnabled)
                await MainActor.run {
                    self.refreshParticipantsFromRoom(shouldNotify: true)
                    completion(nil)
                    self.stateHandler?(WKRTCMediaEngineState.connected, nil)
                }
            } catch {
                await MainActor.run {
                    completion(error)
                    self.stateHandler?(WKRTCMediaEngineState.failed, error)
                }
            }
        }
    }

    /// 只负责与 LiveKit 建连和发布本地轨道，UI 状态回写由调用方切回主线程处理。
    private func connectInternal(
        withURL url: String,
        token: String,
        audioEnabled: Bool,
        videoEnabled: Bool
    ) async throws {
        print("音视频开始连接 LiveKit 房间：\(url)")
        try await room.connect(url: url, token: token)
        print("音视频 LiveKit 房间连接成功")
        if audioEnabled {
            try await room.localParticipant.setMicrophone(enabled: true)
            print("音视频本地麦克风已发布")
        }
        if videoEnabled {
            try await room.localParticipant.setCamera(
                enabled: true,
                captureOptions: cameraCaptureOptions,
                publishOptions: cameraPublishOptions
            )
            await MainActor.run {
                attachLocalCameraTrackIfNeeded()
            }
            print("音视频本地摄像头已发布")
        }
    }

    /// 主动断开房间，业务结束接口失败时也需要执行本地断开。
    func disconnect(completion: (() -> Void)?) {
        Task { [weak self] in
            guard let self else { return }
            await room.disconnect()
            DispatchQueue.main.async {
                self.localVideo.track = nil
                self.remoteVideo.track = nil
                self.participantVideoViews.values.forEach { $0.track = nil }
                self.participantVideoViews.removeAll()
                self.participantIds.removeAll()
                self.participantStateMap.removeAll()
                completion?()
                self.stateHandler?(WKRTCMediaEngineState.disconnected, nil)
            }
        }
    }

    /// 设置本地麦克风发布状态。
    @nonobjc func setAudioEnabled(_ enabled: Bool) async throws {
        try await room.localParticipant.setMicrophone(enabled: enabled)
    }

    /// ObjC 业务层调用的麦克风开关回调形式。
    func setAudioEnabled(_ enabled: Bool, completion: (@Sendable (Error?) -> Void)? = nil) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await setAudioEnabled(enabled)
                await MainActor.run { completion?(nil) }
            } catch {
                await MainActor.run { completion?(error) }
            }
        }
    }

    /// 设置本地摄像头发布状态。
    @nonobjc func setVideoEnabled(_ enabled: Bool) async throws {
        try await room.localParticipant.setCamera(
            enabled: enabled,
            captureOptions: enabled ? cameraCaptureOptions : nil,
            publishOptions: enabled ? cameraPublishOptions : nil
        )
        await MainActor.run {
            if enabled {
                attachLocalCameraTrackIfNeeded()
            } else {
                localVideo.track = nil
            }
            updateParticipantState(room.localParticipant)
            postParticipantsChanged()
        }
    }

    /// ObjC 业务层调用的摄像头开关回调形式。
    func setVideoEnabled(_ enabled: Bool, completion: (@Sendable (Error?) -> Void)? = nil) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await setVideoEnabled(enabled)
                await MainActor.run { completion?(nil) }
            } catch {
                await MainActor.run { completion?(error) }
            }
        }
    }

    /// 切换前后摄像头，仅在本地已发布摄像头轨道时执行。
    @nonobjc func switchCamera() async throws {
        guard let cameraTrack = room.localParticipant.firstCameraPublication?.track as? LocalVideoTrack,
              let cameraCapturer = cameraTrack.capturer as? CameraCapturer else {
            throw NSError(domain: "未找到正在发布的摄像头", code: -1, userInfo: [NSLocalizedDescriptionKey: "未找到正在发布的摄像头"])
        }
        _ = try await cameraCapturer.switchCameraPosition()
    }

    /// ObjC 业务层调用的前后摄像头翻转回调形式。
    func switchCamera(completion: (@Sendable (Error?) -> Void)? = nil) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await switchCamera()
                await MainActor.run {
                    self.postParticipantsChanged()
                    completion?(nil)
                }
            } catch {
                await MainActor.run { completion?(error) }
            }
        }
    }

    func localVideoView() -> UIView {
        localVideo
    }

    func remoteVideoView() -> UIView {
        remoteVideo
    }

    func currentParticipants() -> [String] {
        participantIds
    }

    func participantStates() -> [String: WKRTCMediaParticipantState] {
        participantStateMap
    }

    /// 群聊网格指定某个远端身份渲染到目标容器。
    func setRemoteParticipant(_ participantId: String, videoView: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let liveKitView = participantVideoViews[participantId] ?? VideoView()
            participantVideoViews[participantId] = liveKitView
            if liveKitView.superview !== videoView {
                videoView.subviews.forEach { $0.removeFromSuperview() }
                liveKitView.frame = videoView.bounds
                liveKitView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                videoView.addSubview(liveKitView)
            }
        }
    }

    /// 群聊网格只订阅当前可见成员的视频，隐藏成员保留音频订阅，降低弱网和多人场景压力。
    func setVisibleRemoteParticipants(_ participantIds: [String]) {
        let visibleSet = Set(participantIds)
        Task { [weak self] in
            guard let self else { return }
            for participant in room.remoteParticipants.values {
                guard let identity = participant.identity?.stringValue, !identity.isEmpty else { continue }
                let shouldSubscribeVideo = visibleSet.contains(identity)
                for publication in participant.videoTracks.compactMap({ $0 as? RemoteTrackPublication }) {
                    do {
                        try await publication.set(subscribed: shouldSubscribeVideo)
                        if shouldSubscribeVideo {
                            try await publication.set(videoQuality: .high)
                        }
                    } catch {
                        print("音视频设置远端视频订阅失败：\(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// 使用 iOS 原生视频通话画中画，收起到桌面后仍由系统显示远端视频。
    func preparePictureInPicture(withSourceView sourceView: UIView) {
        if Thread.isMainThread {
            preparePictureInPictureController(withSourceView: sourceView)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.preparePictureInPictureController(withSourceView: sourceView)
            }
        }
    }

    /// 使用 iOS 原生视频通话画中画，收起到桌面后仍由系统显示远端视频。
    func startPictureInPicture(withSourceView sourceView: UIView, completion: (@Sendable (Error?) -> Void)? = nil) {
        if Thread.isMainThread {
            performStartPictureInPicture(withSourceView: sourceView, completion: completion)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.performStartPictureInPicture(withSourceView: sourceView, completion: completion)
            }
        }
    }

    private func performStartPictureInPicture(withSourceView sourceView: UIView, completion: (@Sendable (Error?) -> Void)?) {
        guard #available(iOS 15.0, *) else {
            completion?(NSError(domain: "WKRTC", code: -1, userInfo: [NSLocalizedDescriptionKey: "当前系统版本不支持画中画"]))
            return
        }
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            completion?(NSError(domain: "WKRTC", code: -1, userInfo: [NSLocalizedDescriptionKey: "当前设备不支持画中画"]))
            return
        }
        guard sourceView.window != nil, !sourceView.bounds.isEmpty else {
            completion?(NSError(domain: "WKRTC", code: -1, userInfo: [NSLocalizedDescriptionKey: "画中画视频窗口还没有准备好"]))
            return
        }
        if pictureInPictureController?.isPictureInPictureActive == true {
            completion?(nil)
            return
        }
        guard let controller = preparePictureInPictureController(withSourceView: sourceView) else {
            completion?(NSError(domain: "WKRTC", code: -1, userInfo: [NSLocalizedDescriptionKey: "画中画控制器准备失败"]))
            return
        }
        pictureInPictureStartCompletion = completion
        print("音视频准备启动画中画，possible：\(controller.isPictureInPicturePossible)")
        controller.startPictureInPicture()
    }

    @discardableResult
    private func preparePictureInPictureController(withSourceView sourceView: UIView) -> AVPictureInPictureController? {
        guard #available(iOS 15.0, *) else { return nil }
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return nil }
        guard sourceView.window != nil, !sourceView.bounds.isEmpty else { return nil }
        sourceView.layoutIfNeeded()
        if let controller = pictureInPictureController, pictureInPictureSourceView === sourceView {
            if let contentView = pictureInPictureContentViewController?.view {
                attachPictureInPictureVideo(to: contentView)
            }
            return controller
        }
        let contentViewController = AVPictureInPictureVideoCallViewController()
        contentViewController.preferredContentSize = CGSize(width: 1080.0, height: 1920.0)
        attachPictureInPictureVideo(to: contentViewController.view)
        let source = AVPictureInPictureController.ContentSource(activeVideoCallSourceView: sourceView, contentViewController: contentViewController)
        let controller = AVPictureInPictureController(contentSource: source)
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.delegate = self
        pictureInPictureSourceView = sourceView
        pictureInPictureContentViewController = contentViewController
        pictureInPictureController = controller
        print("音视频已准备系统画中画控制器，possible：\(controller.isPictureInPicturePossible)")
        return controller
    }

    /// 结束通话或恢复全屏前停止系统画中画。
    func stopPictureInPicture(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { completion?(); return }
            if self.pictureInPictureController?.isPictureInPictureActive == true {
                self.pictureInPictureStopCompletion = completion
                self.pictureInPictureController?.stopPictureInPicture()
                return
            }
            completion?()
        }
    }

    func setStateChangedHandler(_ handler: ((WKRTCMediaEngineState, Error?) -> Void)?) {
        stateHandler = handler
    }

    // MARK: - AVPictureInPictureControllerDelegate

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print("音视频启动画中画失败：\(error.localizedDescription)")
        let completion = pictureInPictureStartCompletion
        pictureInPictureStartCompletion = nil
        pictureInPictureContentViewController = nil
        pictureInPictureSourceView = nil
        self.pictureInPictureController = nil
        pictureInPictureVideo.track = nil
        completion?(error)
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("音视频画中画已启动")
        let completion = pictureInPictureStartCompletion
        pictureInPictureStartCompletion = nil
        completion?(nil)
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        pictureInPictureContentViewController = nil
        pictureInPictureSourceView = nil
        self.pictureInPictureController = nil
        pictureInPictureVideo.track = nil
        let completion = pictureInPictureStopCompletion
        pictureInPictureStopCompletion = nil
        completion?()
        postParticipantsChanged()
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        NotificationCenter.default.post(name: NSNotification.Name("WKRTCPictureInPictureRestoreRequested"), object: self)
        completionHandler(true)
    }

    // MARK: - RoomDelegate

    func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldConnectionState: ConnectionState) {
        DispatchQueue.main.async { [weak self] in
            print("音视频 LiveKit 连接状态变化：\(oldConnectionState) -> \(connectionState)")
            switch connectionState {
            case .connected:
                self?.refreshParticipantsFromRoom(shouldNotify: true)
                self?.stateHandler?(WKRTCMediaEngineState.connected, nil)
            case .reconnecting:
                self?.stateHandler?(WKRTCMediaEngineState.reconnecting, nil)
            case .disconnected:
                self?.stateHandler?(WKRTCMediaEngineState.disconnected, nil)
            default:
                break
            }
        }
    }

    func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            ensureRemoteParticipant(participant)
            postPresenceChanged(participant: participant, action: WKRTCMediaParticipantPresenceActionJoined)
            postParticipantsChanged()
        }
    }

    func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        guard let identity = participant.identity?.stringValue, !identity.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            participantIds.removeAll { $0 == identity }
            participantVideoViews[identity]?.track = nil
            participantVideoViews.removeValue(forKey: identity)
            participantStateMap.removeValue(forKey: identity)
            postPresenceChanged(participantId: identity, action: WKRTCMediaParticipantPresenceActionLeft)
            postParticipantsChanged()
        }
    }

    func room(_ room: Room, didUpdateSpeakingParticipants participants: [Participant]) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            refreshParticipantsFromRoom(shouldNotify: true)
        }
    }

    func room(_ room: Room, participant: Participant, didUpdateConnectionQuality quality: ConnectionQuality) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            updateParticipantState(participant)
            postParticipantsChanged()
        }
    }

    func room(_ room: Room, participant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) {
        print("音视频本地轨道发布成功：\(publication.kind)")
        guard let track = publication.track as? VideoTrack else { return }
        DispatchQueue.main.async { [weak self] in
            self?.localVideo.track = track
            self?.configureMultitaskingCameraAccessIfNeeded(track)
            self?.refreshPictureInPictureVideoTrack()
            self?.updateParticipantState(participant)
            self?.postParticipantsChanged()
        }
    }

    func room(_ room: Room, participant: LocalParticipant, didUnpublishTrack publication: LocalTrackPublication) {
        print("音视频本地轨道取消发布：\(publication.kind)")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if publication.kind == .video {
                localVideo.track = nil
                refreshPictureInPictureVideoTrack()
            }
            updateParticipantState(participant)
            postParticipantsChanged()
        }
    }

    func room(_ room: Room, participant: RemoteParticipant, didPublishTrack publication: RemoteTrackPublication) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            ensureRemoteParticipant(participant)
            updateParticipantState(participant)
            postParticipantsChanged()
        }
    }

    func room(_ room: Room, participant: RemoteParticipant, didUnpublishTrack publication: RemoteTrackPublication) {
        guard let identity = participant.identity?.stringValue, !identity.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if publication.kind == .video {
                participantVideoViews[identity]?.track = nil
                if remoteVideo.track === publication.track {
                    remoteVideo.track = nil
                }
                refreshPictureInPictureVideoTrack()
            }
            updateParticipantState(participant)
            postParticipantsChanged()
        }
    }

    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        guard let identity = participant.identity?.stringValue, !identity.isEmpty else { return }
        print("音视频已订阅远端轨道：\(identity)，类型：\(publication.kind)")
        if publication.kind == .video {
            Task {
                do {
                    try await publication.set(videoQuality: .high)
                    print("音视频已请求远端视频高画质：\(identity)")
                } catch {
                    print("音视频请求远端视频高画质失败：\(identity)，错误：\(error.localizedDescription)")
                }
            }
        }
        guard let track = publication.track as? VideoTrack else {
            DispatchQueue.main.async { [weak self] in
                self?.ensureRemoteParticipant(participant)
                self?.updateParticipantState(participant)
                self?.postParticipantsChanged()
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            ensureRemoteParticipant(participant)
            remoteVideo.track = track
            let liveKitView = participantVideoViews[identity] ?? VideoView()
            liveKitView.track = track
            participantVideoViews[identity] = liveKitView
            refreshPictureInPictureVideoTrack()
            postParticipantsChanged()
        }
    }

    func room(_ room: Room, participant: RemoteParticipant, didFailToSubscribeTrackWithSid trackSid: Track.Sid, error: LiveKitError) {
        let identity = participant.identity?.stringValue ?? ""
        print("音视频订阅远端轨道失败：\(identity)，轨道：\(trackSid)，错误：\(error.localizedDescription)")
    }

    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        guard let identity = participant.identity?.stringValue, !identity.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            participantVideoViews[identity]?.track = nil
            if let track = publication.track as? VideoTrack, remoteVideo.track === track {
                remoteVideo.track = nil
            }
            refreshPictureInPictureVideoTrack()
            updateParticipantState(participant)
            postParticipantsChanged()
        }
    }

    func room(_ room: Room, participant: Participant, trackPublication: TrackPublication, didUpdateIsMuted isMuted: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            updateParticipantState(participant)
            if trackPublication.kind == .video && isMuted {
                if participant is LocalParticipant {
                    localVideo.track = nil
                } else if let identity = participant.identity?.stringValue, !identity.isEmpty {
                    participantVideoViews[identity]?.track = nil
                    remoteVideo.track = nil
                }
            } else if trackPublication.kind == .video {
                attachLocalCameraTrackIfNeeded()
                if let remote = participant as? RemoteParticipant {
                    attachRemoteVideoTrackIfNeeded(remote)
                }
            }
            postParticipantsChanged()
        }
    }

    // MARK: - 参与者状态

    /// 从 LiveKit Room 快照同步参与者列表，避免音频通话没有视频轨道时成员丢失。
    private func refreshParticipantsFromRoom(shouldNotify: Bool) {
        if let localIdentity = room.localParticipant.identity?.stringValue, !localIdentity.isEmpty {
            updateParticipantState(room.localParticipant)
        }
        attachLocalCameraTrackIfNeeded()

        let remoteIdentities = room.remoteParticipants.values.compactMap { $0.identity?.stringValue }.filter { !$0.isEmpty }
        let remoteSet = Set(remoteIdentities)
        participantIds.removeAll { !remoteSet.contains($0) }
        for participant in room.remoteParticipants.values {
            ensureRemoteParticipant(participant)
            attachRemoteVideoTrackIfNeeded(participant)
        }

        var validIds = remoteSet
        if let localIdentity = room.localParticipant.identity?.stringValue, !localIdentity.isEmpty {
            validIds.insert(localIdentity)
        }
        for participantId in Array(participantStateMap.keys) where !validIds.contains(participantId) {
            participantStateMap.removeValue(forKey: participantId)
        }

        if shouldNotify {
            postParticipantsChanged()
        }
    }

    /// 主动绑定本地已发布摄像头轨道，避免发布回调早于 UI 绑定导致本地预览为空。
    private func attachLocalCameraTrackIfNeeded() {
        guard let publication = room.localParticipant.firstCameraPublication,
              !publication.isMuted,
              let track = publication.track as? VideoTrack else {
            localVideo.track = nil
            refreshPictureInPictureVideoTrack()
            return
        }
        configureMultitaskingCameraAccessIfNeeded(track)
        localVideo.track = track
        refreshPictureInPictureVideoTrack()
    }

    /// 进入系统画中画或后台时继续采集本地摄像头，避免对方看到本端视频中断。
    private func configureMultitaskingCameraAccessIfNeeded(_ track: VideoTrack) {
        guard !didConfigureMultitaskingCamera,
              let localTrack = track as? LocalVideoTrack,
              let cameraCapturer = localTrack.capturer as? CameraCapturer else {
            return
        }
        didConfigureMultitaskingCamera = true
        if cameraCapturer.isMultitaskingAccessSupported {
            cameraCapturer.isMultitaskingAccessEnabled = true
            print("音视频已开启后台画中画摄像头采集")
        } else {
            print("音视频当前设备或签名不支持后台画中画摄像头采集")
        }
    }

    /// 主动绑定远端已订阅视频轨道，避免加入房间时已有轨道但 UI 未收到订阅回调。
    private func attachRemoteVideoTrackIfNeeded(_ participant: RemoteParticipant) {
        guard let identity = participant.identity?.stringValue, !identity.isEmpty else { return }
        for publication in participant.videoTracks.compactMap({ $0 as? RemoteTrackPublication }) {
            guard publication.isSubscribed, !publication.isMuted, let track = publication.track as? VideoTrack else { continue }
            Task {
                do {
                    try await publication.set(videoQuality: .high)
                } catch {
                    print("音视频请求远端视频高画质失败：\(identity)，错误：\(error.localizedDescription)")
                }
            }
            remoteVideo.track = track
            let liveKitView = participantVideoViews[identity] ?? VideoView()
            liveKitView.track = track
            participantVideoViews[identity] = liveKitView
            refreshPictureInPictureVideoTrack()
            print("音视频已绑定远端视频轨道：\(identity)")
            return
        }
        participantVideoViews[identity]?.track = nil
        remoteVideo.track = nil
        refreshPictureInPictureVideoTrack()
    }

    /// PiP 只显示视频画面，不叠加“视频通话”或通话时长。
    private func attachPictureInPictureVideo(to container: UIView) {
        container.backgroundColor = .black
        refreshPictureInPictureVideoTrack()
        if pictureInPictureVideo.superview !== container {
            container.subviews.forEach { $0.removeFromSuperview() }
            pictureInPictureVideo.translatesAutoresizingMaskIntoConstraints = false
            pictureInPictureVideo.isUserInteractionEnabled = false
            container.addSubview(pictureInPictureVideo)
            NSLayoutConstraint.activate([
                pictureInPictureVideo.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                pictureInPictureVideo.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                pictureInPictureVideo.topAnchor.constraint(equalTo: container.topAnchor),
                pictureInPictureVideo.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
        }
    }

    /// PiP 使用独立 VideoView 绑定同一个 LiveKit track，避免移动全屏通话页里的视频 view。
    private func refreshPictureInPictureVideoTrack() {
        let track = currentRemoteCameraTrack() ?? remoteVideo.track ?? localVideo.track
        pictureInPictureVideo.track = track
        if pictureInPictureContentViewController != nil {
            let trackRole: String
            if track == nil {
                trackRole = "无"
            } else if track === localVideo.track {
                trackRole = "本地"
            } else {
                trackRole = "远端"
            }
            print("音视频画中画刷新视频轨道：\(trackRole)，渲染模式：sampleBuffer")
        }
    }

    /// 从 LiveKit 房间实时获取远端摄像头轨道，避免 PiP 使用过期的 remoteVideo 缓存。
    private func currentRemoteCameraTrack() -> VideoTrack? {
        for participant in room.remoteParticipants.values {
            for publication in participant.videoTracks.compactMap({ $0 as? RemoteTrackPublication }) {
                if publication.isSubscribed, !publication.isMuted, let track = publication.track as? VideoTrack {
                    return track
                }
            }
        }
        return nil
    }

    /// 记录远端成员身份；身份来自 LiveKit token，不从业务侧推断。
    private func ensureRemoteParticipant(_ participant: RemoteParticipant) {
        guard let identity = participant.identity?.stringValue, !identity.isEmpty else { return }
        if !participantIds.contains(identity) {
            participantIds.append(identity)
        }
        updateParticipantState(participant)
    }

    /// 将 LiveKit 的网络质量、音量和说话状态转换成 Objective-C 可读模型。
    private func updateParticipantState(_ participant: Participant) {
        guard let identity = participant.identity?.stringValue, !identity.isEmpty else { return }
        let state = participantStateMap[identity] ?? WKRTCMediaParticipantState()
        state.participantId = identity
        state.networkQuality = networkQualityText(participant.connectionQuality)
        state.audioLevel = participant.audioLevel
        state.speaking = participant.isSpeaking
        state.videoEnabled = isParticipantCameraEnabled(participant)
        participantStateMap[identity] = state
    }

    /// 用摄像头发布轨道的静音状态判断对端是否关闭摄像头。
    private func isParticipantCameraEnabled(_ participant: Participant) -> Bool {
        guard let publication = participant.firstCameraPublication else { return false }
        return !publication.isMuted
    }

    /// 使用文档约定的英文枚举值交给 ObjC 层展示，避免 UI 依赖 LiveKit 类型。
    private func networkQualityText(_ quality: ConnectionQuality) -> String {
        switch quality {
        case .lost:
            return "lost"
        case .poor:
            return "poor"
        case .good:
            return "good"
        case .excellent:
            return "excellent"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }

    private func postParticipantsChanged() {
        NotificationCenter.default.post(name: NSNotification.Name.WKRTCMediaParticipantsDidChange, object: self)
    }

    /// 将 LiveKit 成员进出房间事件转给 ObjC 层，UI 不直接依赖 LiveKit 类型。
    private func postPresenceChanged(participant: Participant, action: String) {
        guard let identity = participant.identity?.stringValue, !identity.isEmpty else { return }
        postPresenceChanged(participantId: identity, action: action)
    }

    private func postPresenceChanged(participantId: String, action: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name.WKRTCMediaParticipantPresenceDidChange,
            object: self,
            userInfo: [
                "participant_id": participantId,
                "action": action
            ]
        )
    }
}
