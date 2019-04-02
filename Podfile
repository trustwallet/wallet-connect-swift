platform :ios, '11.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

target 'WallectConnect' do
  use_frameworks!

  pod 'TrustWalletCore'
  pod 'CryptoSwift'
  pod 'Starscream'
  pod 'PromiseKit'
  pod 'SwiftLint'

  target 'WallectConnectTests' do
    inherit! :search_paths
    pod 'CryptoSwift'
    pod 'Starscream'
    pod 'PromiseKit'
  end
end

target 'WalletConnectApp' do
  use_frameworks!
end
