platform :ios, '10.0'

use_modular_headers!
inhibit_all_warnings!
workspace 'TokenDWalletTemplate'
source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:tokend/ios-specs.git'

def main_app_pods
    pod 'QRCodeReader.swift',       '8.1.1'
    # pod 'ReachabilitySwift',        '~> 4.1'
    pod 'RxCocoa',                  '~> 4.1'
    pod 'RxSwift',                  '~> 4.1'
    pod 'SnapKit',                  '~> 4.0'
    pod 'SwiftKeychainWrapper',     '3.0.1'
    
    pod 'SideMenuController', :git => 'https://github.com/tokend/SideMenuController.git'
    pod 'Charts', :git => 'https://github.com/tokend/Charts.git', :branch => 'master'

    pod 'TokenDSDK',                '< 2.0'
    pod 'PullToRefresher',          '~> 3.0'
    pod 'Nuke'           ,          '7.6.3'

end

target 'TokenDWalletTemplate' do
    main_app_pods
    
    post_install do |installer|
        targetsToDisableBitcode = ['TokenDSDK', 'DLCryptoKit']
        
        installer.pods_project.targets.each do |target|
            if targetsToDisableBitcode.include? target.name
                target.build_configurations.each do |config|
                    config.build_settings['ENABLE_BITCODE'] = 'NO'
                end
            end
        end
        
        deploymentTargets = ['libsodium']
        
        installer.pods_project.targets.each do |target|
            if deploymentTargets.include? target.name
                target.build_configurations.each do |config|
                    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
                end
            end
        end
        
        swift4Targets = ['QRCodeReader.swift', 'ActionsList']
        
        installer.pods_project.targets.each do |target|
          next unless swift4Targets.include? target.name
          
          target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4'
          end
        end
    end
end
