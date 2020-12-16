platform :ios, '11.0'

use_modular_headers!
inhibit_all_warnings!
workspace 'TokenDWalletTemplate'
source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:tokend/ios-specs.git'

def main_app_pods
  pod 'TokenDSDK',                          '3.2.0-rc.6'
  pod 'TokenDSDK/AlamofireNetwork',         '3.2.0-rc.6'
  pod 'TokenDSDK/JSONAPI',                  '3.2.0-rc.6'
  pod 'TokenDSDK/AlamofireNetworkJSONAPI',  '3.2.0-rc.6'
  pod 'TokenDSDK/KeyServer',                '3.2.0-rc.6'
  
  pod 'QRCodeReader.swift',       '8.1.1'
#  pod 'ReachabilitySwift',        '~> 4.1'
  pod 'RxCocoa',                  '5.1.0'
  pod 'RxSwift',                  '5.1.0'
  pod 'SnapKit',                  '~> 4.0'
  pod 'SwiftKeychainWrapper',     '3.0.1'
  pod 'ActionsList', :git => 'https://github.com/LowKostKustomz/ActionsList.git', :branch => 'hotfix/swift_5.0_compatibility_stable'
  
  pod 'PullToRefresher', '~> 3.0'
  pod 'Nuke', '7.6.3'
  pod 'MarkdownView'
  pod 'AFDateHelper', '~> 4.2.2'
  
#  pod 'Firebase/Core', '6.26.0'
#  pod 'Fabric'
#  pod 'Crashlytics'
  
  pod 'SideMenuController', git: 'https://github.com/tokend/SideMenuController.git'
  pod 'Charts', git: 'https://github.com/tokend/Charts.git'
  pod 'Floaty', git: 'https://github.com/tokend/Floaty.git'
  pod 'UICircularProgressRing'
end

target 'TokenDWalletTemplate' do
  main_app_pods

  post_install do |installer|
    # targetsToDisableBitcode = %w[TokenDSDK DLCryptoKit]
    #
    # installer.pods_project.targets.each do |target|
    #   next unless targetsToDisableBitcode.include? target.name
    #
    #   target.build_configurations.each do |config|
    #     config.build_settings['ENABLE_BITCODE'] = 'NO'
    #   end
    # end

#    swift3Targets = ['SideMenuController']
#
#    installer.pods_project.targets.each do |target|
#      next unless swift3Targets.include? target.name
#
#      target.build_configurations.each do |config|
#        config.build_settings['SWIFT_VERSION'] = '3.2'
#      end
#    end
    
    swift4Targets = ['QRCodeReader.swift']
    
    installer.pods_project.targets.each do |target|
      next unless swift4Targets.include? target.name
      
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4'
      end
    end

    
    swift42Targets = ['Charts']
       
       installer.pods_project.targets.each do |target|
         next unless swift42Targets.include? target.name
         
         target.build_configurations.each do |config|
           config.build_settings['SWIFT_VERSION'] = '4.2'
         end
       end


    # copy Acknowledgements
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-TokenDWalletTemplate/Pods-TokenDWalletTemplate-acknowledgements.markdown', 'TokenDWalletTemplate/Resources/acknowledgements.markdown')
  end
end
