platform :ios, '11.0'
workspace 'TokenDClient'

use_modular_headers!
inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/tokend/ios-specs.git'

def token_d_pods
  
  pod 'TokenDSDK',                          '4.0.4'
  pod 'TokenDSDK/AlamofireNetwork',         '4.0.4'
  pod 'TokenDSDK/JSONAPI',                  '4.0.4'
  pod 'TokenDSDK/AlamofireNetworkJSONAPI',  '4.0.4'
  pod 'TokenDSDK/KeyServer',                '4.0.4'
  
end

def ui_pods
  
  pod 'RxSwift',                  '6.0.0-rc.1'
  pod 'RxCocoa',                  '6.0.0-rc.1'
  
  pod 'SwiftKeychainWrapper',     '4.0.1'
  pod 'SnapKit',                  '5.0.1'
  pod 'DifferenceKit',            '1.1.5'
  pod 'QRCodeReader.swift', 	    '10.1.0'
  pod 'Nuke',                     '9.1.2'
end

def other_pods
end

target 'Client' do
  token_d_pods
  ui_pods
end
