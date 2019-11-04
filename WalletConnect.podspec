Pod::Spec.new do |s|
  s.name             = 'WalletConnect'
  s.version          = '0.1.0'
  s.summary          = 'WalletConnect Swift SDK'
  s.description      = 'WalletConnect Swift SDK'

  s.homepage         = 'https://github.com/hewigovens/wallet-connect-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'hewigovens' => '360470+hewigovens@users.noreply.github.com' }
  s.source           = { :git => 'https://github.com/hewigovens/WalletConnect.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.source_files = 'WalletConnect/**/*'
  s.exclude_files = ["WalletConnect/Info.plist"]
  s.swift_version = '5.0'

  s.dependency 'CryptoSwift'
  s.dependency 'Starscream'
  s.dependency 'PromiseKit'
end
