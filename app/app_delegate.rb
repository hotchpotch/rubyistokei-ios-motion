class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = RTViewController.new
    @window.rootViewController.wantsFullScreenLayout = true
    @window.makeKeyAndVisible

    application.idleTimerDisabled = true
    true
  end
end

module Kernel
  def log(*args)
    puts *args if ENV['log']
  end

  def log_p(*args)
    p *args if ENV['log']
  end
end

class RTViewController < UIViewController
  def supportedInterfaceOrientations
    UIInterfaceOrientationMaskAll
  end

  def loadView
    self.view = RTMainView.alloc.initWithFrame([[0,0], UIScreen.mainScreen.bounds.size.to_a.reverse])

    @tokei = RTTokei.new
    view.addSubview @tokei
    @tokei.centering

    RubyistManager.load do |manager|
      @manager = manager
      photo_preload
      check_and_show_next_rubyist
    end

    NSNotificationCenter.defaultCenter.addObserver(self, selector:'glitch!:', name:'glitch', object:nil)
  end

  def glitch!(user_info)
    @current_photo.glitch if @current_photo
    @hidden_photo.glitch if @hidden_photo
    @glitch = true
  end

  def swap_photo!
    self.view.subviews.each do |photo|
      if photo.kind_of? RTPhoto
        photo.fadeOut {
          photo.removeFromSuperview
          photo = nil
        }
      else
        # maybe Tokei
        UIView.animateWithDuration(0.5,
                                   delay: 0.0,
                                   options:UIViewAnimationCurveEaseInOut,
                                   animations: -> {
                                     photo.alpha = 0.0
                                   },
                                   completion: -> (b) {
                                     photo.removeFromSuperview
                                   }
                                  )
      end
    end

    hidden_photo = @hidden_photo
    hidden_photo_tokei = RTTokei.new
    hidden_photo.addSubview(hidden_photo_tokei)
    hidden_photo_tokei.updatePositionWithRubyist hidden_photo.rubyist
    hidden_photo_tokei.color = hidden_photo.rubyist.color
    self.view.addSubview hidden_photo

    @current_photo = hidden_photo
    hidden_photo.fadeIn {
      log "subviews: #{self.view.subviews.size}"
      @tokei = hidden_photo_tokei
      hidden_photo_tokei = nil
      hidden_photo = nil
    }
    @hidden_photo = nil
  end

  def photo_preload
    log 'photo preloading'
    @hidden_photo = RTPhoto.alloc.initWithFrame([[0,0], UIScreen.mainScreen.bounds.size.to_a.reverse])
    @hidden_photo.alpha = 0
    @manager.next_rubyist do |rubyist|
      log "maneger loaded rubyist #{rubyist.name}"
      @hidden_photo.showRubyist(rubyist, @glitch) do |image_load_successed|
        if image_load_successed
          @next_photo_loaded = true
        else
          photo_preload
        end
      end
    end
  end

  def check_and_show_next_rubyist
    show_next_rubyist unless @now_changing
  end

  def show_next_rubyist
    @now_changing = true
    if @next_photo_loaded
      self.swap_photo!
      @next_photo_loaded = false
      @now_changing = false
      photo_preload
      return
    end

    Dispatch::Queue.concurrent.async do
      log 'waiting...'
      sleep 1
      Dispatch::Queue.main.sync do
        show_next_rubyist
      end
    end
  end

  def viewDidLoad
    startTimer
  end

  attr_reader :timer
  def startTimer
    if @timer
      @timer.invalidate
      @timer = nil
    else
      @timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target:self, selector:'timerFired', userInfo:nil, repeats:true)
    end
  end

  def change_rubyist?
    @manager && change_10sec?
  end

  def change_10sec?
    Time.now.strftime("%S")[-1] == "9"
  end

  def change_minute?
    Time.now.strftime("%S") == "59"
  end

  def timerFired
    if change_rubyist?
      check_and_show_next_rubyist
    end
    @tokei.updateTokeiView
  end
end

class RTMainView < UIView
  def touchesEnded(touches, withEvent:event)
    if touches.anyObject.tapCount >= 7
      notify = NSNotification.notificationWithName("glitch", object: self)
      NSNotificationCenter.defaultCenter.postNotification(notify)
    end
  end
end

class RTTokei < UIView
  CLOCK_FORMAT = "%H %M"

  attr_reader :time_label
  def init
    s = super

    font = UIFont.fontWithName("AvenirNext-Medium", size: 60)
    # font = UIFont.fontWithName("HelveticaNeue-Thin", size: 60)
    @text_size = RTTextUtil.text(timeString, sizeWithFont: font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    hour_text_size = RTTextUtil.text("00", sizeWithFont: font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)

    @time_label = UILabel.new
    @time_label.font = font
    @time_label.textAlignment = NSTextAlignmentLeft
    @time_label.backgroundColor = UIColor.clearColor
    @time_label.text = timeString
    @time_label.frame = [[0,0], @text_size]
    addSubview(@time_label)

    separator_text_size= ":".sizeWithFont(font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    @separator = UILabel.new
    # tfont = UIFont.fontWithName("AvenirNext-Bold", size: 60)
    @separator.font = font
    @separator.backgroundColor = @time_label.backgroundColor
    @separator.text = ":"
    @separator.frame = [[hour_text_size.width, 0], separator_text_size]
    addSubview(@separator)
    self.color = UIColor.whiteColor
    s
  end

  def color=(ui_color)
      if ui_color.respond_to? :to_color
        begin
          ui_color = ui_color.to_color
        rescue
          log "color convert error #{ui_color}"
          ui_color = UIColor.whiteColor
        end
      end
      @time_label.textColor = @separator.textColor = ui_color
  end

  def centering
    frame = superview.frame
    textareaHeight = @text_size.height
    origin = frame.origin
    size = frame.size
    origin.y = (size.height - @text_size.height) / 2
    origin.x = (size.width - @text_size.width) / 2

    frame.origin = origin
    #frame.size = size
    self.frame = frame
    setNeedsLayout
  end

  def updatePositionWithRubyist(rubyist)
    if superview.image
      frame = AVMakeRectWithAspectRatioInsideRect(superview.image.size, superview.bounds)
      log_p frame
      size = frame.size
      #<CGRect origin=#<CGPoint x=44.1171264648438 y=0.0> size=#<CGSize width=479.765747070312 height=320.0>>
      origin = frame.origin
      origin.x += (size.width / 1024) * rubyist.left
      origin.y += (size.height / 760) * rubyist.top
      log_p origin
      frame.origin = origin

      self.frame = frame
    end
  end

  def timeString
    Time.now.strftime(CLOCK_FORMAT)
  end

  def updateTokeiView
    @separator.hidden = !@separator.hidden?
    self.time_label.text = timeString
  end
end

class RTPhoto < UIImageView
  attr_accessor :rubyist
  def showRubyist(rubyist, glitch, &block)
    log 'this is showRubyist'
    self.rubyist = rubyist
    self.contentMode = UIViewContentModeScaleAspectFit

    Dispatch::Queue.concurrent.async do
      image_data = NSData.alloc.initWithContentsOfURL(NSURL.URLWithString(rubyist.image_url))
      if image_data
        image = UIImage.alloc.initWithData(image_data)
        if glitch
          image = image.glitch
        end
        Dispatch::Queue.main.sync do
          self.image = image
          unless @textarea
            @textarea = RTTextarea.new
            addSubview @textarea
          end
          @textarea.renderRubyist rubyist
          block.call true
        end
      else
        log "fail image load #{rubyist.name} #{rubyist.image_url}"
        Dispatch::Queue.main.sync do
          block.call false
        end
      end
    end
  end

  def fadeIn(&block)
    UIView.animateWithDuration(1.0,
                             delay: 0.0,
                             options:UIViewAnimationCurveEaseInOut,
                             animations: -> {
                               self.alpha = 1.0
                             },
                             completion: -> (b) {
                               block.call
                             }
                       )
  end

  def fadeOut(&block)
    UIView.animateWithDuration(0.5,
                             delay: 0.0,
                             options:UIViewAnimationCurveEaseInOut,
                             animations: -> {
                               self.alpha = 0.0
                             },
                             completion: -> (b) {
                               block.call
                             }
                       )
  end
end

class RTTextarea < UIView
  PADDING = 5

  def init
    textarea = super
    self.backgroundColor = UIColor.blackColor.colorWithAlphaComponent(0.7)
    textarea
  end

  def textareaHeight
    # XXX: auto calc
    if @name
      # rendered
      frame = @bio.frame
      frame.origin.y + frame.size.height + 3
    else
      60
    end
  end

  def calcFontAndTextSize(text, maxWidth, fontSize, fontName = "AvenirNext-Medium")
    begin
      font = UIFont.fontWithName(fontName, size: fontSize)
      fontSize -= 1
      break if fontSize <= 1
      textSize = (text || '').sizeWithFont(font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    end while textSize.width > maxWidth
    [font, textSize]
  end

  def createLabel(text, font)
    UILabel.new.tap {|label|
      label.font = font
      label.textColor = UIColor.whiteColor
      label.backgroundColor = UIColor.clearColor
      label.text = text
    }
  end

  def renderName(text = '')
    # XXX: The regend
    text = 'no name' if text.size == 0
    font, textSize = calcFontAndTextSize(text, frame.size.width * 2 / 3, 30, "AvenirNext-Bold")
    @name = createLabel(text, font)
    @name.frame = [[PADDING, 0], textSize]
    addSubview(@name)
  end

  def renderTitle(text = '')
    name_text_size = @name.frame.size
    font, textSize = calcFontAndTextSize(text, frame.size.width - (name_text_size.width + PADDING * 3), 16)
    @title = createLabel(text, font)
    @title.frame = [[name_text_size.width + PADDING * 2, name_text_size.height - textSize.height - PADDING],
                    textSize]
    addSubview(@title)
  end

  def renderBio(text = '')
    font, textSize = calcFontAndTextSize(text, frame.size.width * 2 / 3, 16)
    @bio = createLabel(text, font)
    @bio.frame = [[PADDING, secondLineHeight], textSize]
    addSubview(@bio)
  end

  def renderTakenBy(text = '')
    text = " — Photo taken by #{text}"
    bio_text_size = @bio.frame.size
    font, textSize = calcFontAndTextSize(text, frame.size.width - (bio_text_size.width + PADDING * 3), [13, @bio.font.pointSize].min, "AvenirNext-MediumItalic")
    @taken_by = createLabel(text, font)
    @taken_by.frame = [[bio_text_size.width + PADDING * 2, secondLineHeight + bio_text_size.height - textSize.height],
                    textSize]
    addSubview(@taken_by)
  end

  def secondLineHeight
    @name.frame.size.height - PADDING
  end

  def renderRubyist(rubyist)
    setNeedsLayout
    renderName(rubyist.name)
    renderTitle(rubyist.title)
    renderBio(rubyist.bio)
    renderTakenBy(rubyist.taken_by)
    setNeedsLayout
  end

  def setNeedsLayout
    if superview
      frame = AVMakeRectWithAspectRatioInsideRect(superview.image.size, superview.bounds);
      origin = frame.origin
      size = frame.size
      origin.y = size.height - textareaHeight
      size.height = textareaHeight + 2 # XXX: for retina iPad

      frame.origin = origin
      frame.size = size
      self.frame = frame
    end
  end
end

class RTTextUtil
  def self.text(text, sizeWithFont:font, constrainedToSize:size, lineBreakMode:lineBreakMode)
    return text.sizeWithFont(font, constrainedToSize:size, lineBreakMode:lineBreakMode)
  end

  def self.attributesWithFont(font, color:color, lineBreakMode:lineBreakMode)
    paragraph = NSMutableParagraphStyle.new
    paragraph.lineBreakMode = lineBreakMode
    return {
      NSFontAttributeName            => font,
      NSForegroundColorAttributeName => color,
      NSParagraphStyleAttributeName  => paragraph,
    }
  end
end
