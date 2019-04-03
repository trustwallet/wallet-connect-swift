platform :ios, '11.0'
ENV['COCOAPODS_DISABLE_STATS'] = 'true'
inhibit_all_warnings!

target 'WalletConnectApp' do
  use_frameworks!
  pod 'TrustWalletCore'
end

target 'WallectConnect' do
  use_frameworks!

  pod 'CryptoSwift'
  pod 'Starscream'
  pod 'PromiseKit'

  target 'WallectConnectTests' do
    inherit! :search_paths
    pod 'CryptoSwift'
    pod 'Starscream'
    pod 'PromiseKit'
  end
end
