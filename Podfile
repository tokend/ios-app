platform :ios, '10.0'

use_modular_headers!
inhibit_all_warnings!
workspace 'TokenDWalletTemplate'
source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:tokend/ios-specs.git'

def main_app_pods
    pod 'QRCodeReader.swift',       '8.1.1'
    pod 'ReachabilitySwift',        '4.1.0'
    pod 'RxCocoa',                  '4.1.2'
    pod 'RxSwift',                  '4.1.2'
    pod 'SnapKit',                  '4.0.0'
    pod 'SwiftKeychainWrapper',     '3.0.1'
    
    pod 'SideMenuController', :git => 'https://github.com/tokend/SideMenuController.git', :commit => '71763cbdd40cc717cdebb467d2f14b54cde359f7'
    pod 'Charts', :git => 'https://github.com/tokend/Charts.git', :branch => 'master'

    pod 'TokenDSDK',                '< 2.0'
    pod 'PullToRefresher',          '~> 3.0'
    pod 'Nuke'

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
        
        swift3Targets = ['SideMenuController']
        
        installer.pods_project.targets.each do |target|
            if swift3Targets.include? target.name
                target.build_configurations.each do |config|
                    config.build_settings['SWIFT_VERSION'] = '3.2'
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
    end
end
