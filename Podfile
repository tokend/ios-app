platform :ios, '10.0'

use_modular_headers!
inhibit_all_warnings!
workspace 'TokenDWalletTemplate'
source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:tokend/ios-specs.git'

def main_app_pods
  pod 'TokenDSDK', '3.1.0-rc.7'
  pod 'TokenDSDK/AlamofireNetwork'
  pod 'TokenDSDK/JSONAPI'
  pod 'TokenDSDK/AlamofireNetworkJSONAPI'
  pod 'TokenDSDK/KeyServer'
  
  pod 'QRCodeReader.swift',       '8.1.1'
#  pod 'ReachabilitySwift',        '~> 4.1'
  pod 'RxCocoa',                  '~> 4.1'
  pod 'RxSwift',                  '~> 4.1'
  pod 'SnapKit',                  '~> 4.0'
  pod 'SwiftKeychainWrapper',     '3.0.1'
  pod 'ActionsList', :git => 'https://github.com/LowKostKustomz/ActionsList.git', :branch => 'hotfix/swift_5.0_compatibility_stable'
  
  pod 'PullToRefresher', '~> 3.0'
  pod 'Nuke'
  pod 'MarkdownView'
  pod 'AFDateHelper', '~> 4.2.2'
  
  pod 'Firebase/Core'
  pod 'Fabric'
  pod 'Crashlytics'
  
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
