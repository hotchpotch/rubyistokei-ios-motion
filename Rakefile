# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'RubyisTokei'
  app.deployment_target = '7.0'
  app.info_plist['UIStatusBarHidden'] = true
  app.info_plist['UIViewControllerBasedStatusBarAppearance'] = false
  app.info_plist['UISupportedInterfaceOrientations'] = ['UIInterfaceOrientationLandscapeLeft']

  app.frameworks += ['AVFoundation']
end
