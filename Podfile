source 'https://cdn.cocoapods.org/'
require 'shellwords'

def apply_xcode_recommended_project_format(project)
    project.instance_variable_set(:@object_version, '77')
    project.root_object.compatibility_version = 'Xcode 16.0'
    project.root_object.preferred_project_object_version = '77'
    project.root_object.minimized_project_reference_proxies = '1'
    project.root_object.attributes['BuildIndependentTargetsInParallel'] = '1'
    project.root_object.attributes['LastSwiftUpdateCheck'] = '2610'
    project.root_object.attributes['LastUpgradeCheck'] = '2610'
end

# Uncomment the next line to define a global platform for your project
 platform :ios, '15.0'
workspace 'TangSengDaoDaoiOS.xcworkspace'

post_install do |installer|
    # 填写你自己的开发者团队的team id
    dev_team = "H8PU463W68"
    project = installer.aggregate_targets[0].user_project
    project.targets.each do |target|
        target.build_configurations.each do |config|
            if dev_team.empty? and !config.build_settings['DEVELOPMENT_TEAM'].nil?
                dev_team = config.build_settings['DEVELOPMENT_TEAM']
            end
            # CocoaPods embed-framework scripts use rsync to write into the app bundle.
            # Xcode's user script sandbox blocks that path and causes Sandbox: rsync deny errors.
            config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
        end
    end
    
    # Fix bundle targets' 'Signing Certificate' to 'Sign to Run Locally'
    apply_xcode_recommended_project_format(project)
    apply_xcode_recommended_project_format(installer.pods_project)
    installer.pods_project.build_configurations.each do |config|
        config.build_settings['ENABLE_MODULE_VERIFIER'] = 'NO'
        config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
    end
    installer.pods_project.targets.each do |target|
        if target.respond_to?(:source_build_phase) && target.source_build_phase
            non_source_files = ['module.modulemap', 'NOTICE', 'PrivacyInfo.xcprivacy']
            target.source_build_phase.files.each do |build_file|
                display_name = build_file.display_name
                file_path = build_file.file_ref&.path
                if non_source_files.include?(display_name) || non_source_files.include?(file_path) || non_source_files.include?(File.basename(file_path.to_s))
                    target.source_build_phase.remove_build_file(build_file)
                end
            end
        end

        target.build_configurations.each do |config|
            if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
              config.build_settings['DEVELOPMENT_TEAM'] = dev_team
            end
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            config.build_settings['ENABLE_MODULE_VERIFIER'] = 'NO'
            config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
            config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
            config.build_settings['ENABLE_APP_INTENTS_METADATA_GENERATION'] = 'NO'
            config.build_settings['EXTRACT_APP_INTENTS_METADATA'] = 'NO'
            config.build_settings['LD_WARN_DUPLICATE_LIBRARIES'] = 'NO'
            config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
            config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
            config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -Xcc -Wno-gnu-folding-constant -Xcc -Wno-deprecated-declarations -Xcc -Wno-nullability-completeness'

            library_search_paths = config.build_settings['LIBRARY_SEARCH_PATHS']
            if library_search_paths.is_a?(Array)
                library_search_paths.delete('"${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"')
                library_search_paths.delete('${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}')
                library_search_paths.delete('/usr/lib/swift')
            end
        end
        
    end

    installer.aggregate_targets.each do |aggregate_target|
        aggregate_target.user_project.targets.each do |target|
            target.build_configurations.each do |config|
                framework_search_paths = config.build_settings['FRAMEWORK_SEARCH_PATHS']
                if framework_search_paths.is_a?(Array)
                end
                config.build_settings['ENABLE_APP_INTENTS_METADATA_GENERATION'] = 'NO'
                config.build_settings['EXTRACT_APP_INTENTS_METADATA'] = 'NO'
                config.build_settings['LD_WARN_DUPLICATE_LIBRARIES'] = 'NO'
                config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
                config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
                config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
                config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'NO'
                config.build_settings['CLANG_WARN_NULLABILITY_COMPLETENESS'] = 'NO'
                config.build_settings['OTHER_CFLAGS'] = '$(inherited) -Wno-gnu-folding-constant -Wno-deprecated-declarations -Wno-nullability-completeness'
                config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -Xcc -Wno-gnu-folding-constant -Xcc -Wno-deprecated-declarations -Xcc -Wno-nullability-completeness'
            end
        end
        aggregate_target.user_project.save
    end

    Dir.glob(File.join(installer.sandbox.root, 'Target Support Files', '**', '*.xcconfig')).each do |xcconfig_path|
        content = File.read(xcconfig_path)
        content = content.gsub(' "${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}" /usr/lib/swift', '')
        content = content.gsub('"${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}" /usr/lib/swift', '')
        content = content.lines.map do |line|
            if line.start_with?('OTHER_LDFLAGS = ')
                flags = Shellwords.split(line.sub('OTHER_LDFLAGS = ', ''))
                flags.delete('-lc++')
                if File.basename(xcconfig_path).start_with?('Pods-')
                    flags.delete('-licucore')
                    flags.delete('-lz')
                end
                flags.concat(['-Xlinker', '-no_warn_duplicate_libraries'])
                deduped = []
                seen = {}
                index = 0
                while index < flags.length
                    key = if ['-framework', '-weak_framework'].include?(flags[index]) && index + 1 < flags.length
                        value = [flags[index], flags[index + 1]]
                        index += 2
                        value
                    else
                        value = flags[index]
                        index += 1
                        value
                    end
                    next if seen[key]
                    seen[key] = true
                    deduped.concat(key.is_a?(Array) ? key : [key])
                end
                "OTHER_LDFLAGS = #{deduped.join(' ')}\n"
            else
                line
            end
        end.join
        File.write(xcconfig_path, content)
    end
    installer.pods_project.save
    project.save
end

post_integrate do |installer|
    pods_project_path = File.join(installer.sandbox.root, 'Pods.xcodeproj', 'project.pbxproj')
    if File.exist?(pods_project_path)
        content = File.read(pods_project_path)
        content = content.gsub(/^.*\/\* (PrivacyInfo\.xcprivacy|NOTICE|module\.modulemap) in Sources \*\/.*\n/, '')
        File.write(pods_project_path, content)
    end

    Dir.glob(File.join(installer.sandbox.root, 'Target Support Files', '**', '*-umbrella.h')).each do |umbrella_path|
        content = File.read(umbrella_path)
        support_dir = File.dirname(umbrella_path)
        modulemap_path = Dir.glob(File.join(support_dir, '*.modulemap')).first
        module_name = File.basename(umbrella_path, '-umbrella.h')
        if modulemap_path && File.read(modulemap_path) =~ /framework\s+module\s+([A-Za-z_][A-Za-z0-9_]*)/
            module_name = Regexp.last_match(1)
        end
        content = content.gsub(/#import "([^"]+)"/, "#import <#{module_name}/\\1>")
        content = content.gsub(/#import <#{Regexp.escape(File.basename(umbrella_path, '-umbrella.h'))}\/([^>]+)>/, "#import <#{module_name}/\\1>")
        if File.basename(umbrella_path) == 'FMDB-umbrella.h'
            content = content.gsub(/#import <FMDB\/([^>]+)>/, '#import <fmdb/\1>')
        end
        File.write(umbrella_path, content)
    end
end


abstract_target 'TangSengDaoDaoiOSBase' do
  
#  pod 'lottie-ios', '~> 2.5.3'
  pod 'Socket.IO-Client-Swift'
  pod 'SSZipArchive', '~> 2.2.3'
  pod 'SocketRocket'
  pod 'Aspects'
  pod 'ReactiveObjC'

  target 'TangSengDaoDaoiOS' do
    project 'TangSengDaoDaoiOS.xcodeproj'
    
  use_frameworks!
  pod 'YBImageBrowser/NOSD', :git=>'https://github.com/tangtaoit/YBImageBrowser.git'
  pod 'YYImage/WebP', :git => 'https://github.com/tangtaoit/YYImage.git'
  pod 'AsyncDisplayKit', :git => 'https://github.com/tangtaoit/AsyncDisplayKit.git'
  pod 'librlottie', :git => 'https://github.com/tangtaoit/librlottie.git'
  
  pod 'WuKongIMSDK',  :path => './Modules/WuKongIMiOSSDK'   ## WuKongBase 基础工具包  源码地址 https://github.com/WuKongIM/WuKongIMiOSSDK
#  pod 'WuKongIMSDK',  :path => '../../../wukongIM/iOS/WuKongIMiOSSDK'
#  pod  'WuKongIMSDK', '~> 1.0.2' ## 源码地址 https://github.com/WuKongIM/WuKongIMiOSSDK
  pod 'WuKongBase',  :path => './Modules/WuKongBase'   ## WuKongBase 基础工具包
  pod 'WuKongLogin', :path => './Modules/WuKongLogin'  ##  登录模块
  pod 'WuKongContacts', :path => './Modules/WuKongContacts'  ## 联系人模块
  pod 'WuKongDataSource', :path => './Modules/WuKongDataSource'  ## 数据源
  end
  
end
