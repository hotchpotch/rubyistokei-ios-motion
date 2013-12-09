class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = RubyisTokeiViewController.new
    @window.rootViewController.wantsFullScreenLayout = true
    @window.makeKeyAndVisible
    $window = @window
    true
  end
end

class RubyisTokeiViewController < UIViewController
  def supportedInterfaceOrientations
    UIInterfaceOrientationMaskAll
  end

  def loadView
    self.view = UIView.alloc.initWithFrame([[0,0], UIScreen.mainScreen.bounds.size.to_a.reverse])

    @tokei = RTTokei.new
    view.addSubview @tokei
    @tokei.centering

    RubyistManager.load do |manager|
      @manager = manager
      photo_preload
      check_and_show_next_rubyist
    end
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

    self.view.addSubview hidden_photo
    hidden_photo.fadeIn {
      puts "subviews: #{self.view.subviews.size}"
      @tokei = hidden_photo_tokei
      hidden_photo_tokei = nil
      hidden_photo = nil
    }
    @hidden_photo = nil
  end

  def photo_preload
    puts 'photo preloading'
    # XXX: hidden_photo を使い回すと落ちる
    @hidden_photo = RTPhoto.alloc.initWithFrame([[0,0], UIScreen.mainScreen.bounds.size.to_a.reverse])
    @hidden_photo.alpha = 0
    @manager.next_rubyist do |rubyist|
      puts "maneger loaded rubyist #{rubyist.name}"
      @hidden_photo.showRubyist(rubyist) do
        @next_photo_loaded = true
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
      puts 'waiting...'
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

class RTTokei < UIView
  CLOCK_FORMAT = "%H %M"

  attr_reader :time_label
  def init
    s = super

    # font = UIFont.fontWithName("AvenirNext-Bold", size: 60)
    font = UIFont.fontWithName("HelveticaNeue-Thin", size: 60)
    @text_size = RTTextUtil.text(timeString, sizeWithFont: font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    hour_text_size = RTTextUtil.text("00", sizeWithFont: font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)

    @time_label = UILabel.new
    @time_label.font = font
    @time_label.textAlignment = NSTextAlignmentLeft
    @time_label.textColor = UIColor.whiteColor.colorWithAlphaComponent(0.9)
    @time_label.backgroundColor = UIColor.clearColor
    @time_label.text = timeString
    @time_label.frame = [[0,0], @text_size]
    addSubview(@time_label)

    separator_text_size= ":".sizeWithFont(font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    @separator = UILabel.new
    # tfont = UIFont.fontWithName("AvenirNext-Bold", size: 60)
    @separator.font = font
    @separator.textColor = @time_label.textColor
    @separator.backgroundColor = @time_label.backgroundColor
    @separator.text = ":"
    @separator.frame = [[hour_text_size.width - 4, 0], separator_text_size]
    addSubview(@separator)
    s
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
      p frame
      size = frame.size
      #<CGRect origin=#<CGPoint x=44.1171264648438 y=0.0> size=#<CGSize width=479.765747070312 height=320.0>>
      origin = frame.origin
      origin.x += (size.width / 1024) * rubyist.left
      origin.y += (size.height / 760) * rubyist.top
      p origin
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
  def showRubyist(rubyist, &block)
    puts 'this is showRubyist'
    self.rubyist = rubyist
    self.contentMode = UIViewContentModeScaleAspectFit

    puts 'sR 1'
    Dispatch::Queue.concurrent.async do
    puts 'sR 2'
      image_data = NSData.alloc.initWithContentsOfURL(NSURL.URLWithString(rubyist.image_url))
    puts 'sR 3'
      if image_data
    puts 'sR 4'
        image = UIImage.alloc.initWithData(image_data)
        Dispatch::Queue.main.sync do
    puts 'sR 5'
          self.image = image
          unless @textarea
            @textarea = RTTextarea.new
            addSubview @textarea
          end
    puts 'sR 6'
          @textarea.renderRubyist rubyist
          block.call
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
  attr_reader :rubyist

  def init
    textarea = super
    self.backgroundColor = UIColor.blackColor.colorWithAlphaComponent(0.7)
    textarea
  end

  def textareaHeight
    # XXX: auto calc
    60
  end

  def renderRubyist(rubyist)
    setNeedsLayout

    @name ||= UILabel.new
    @title ||= UILabel.new
    @bio ||= UILabel.new
    @taken_by ||= UILabel.new

    padding = 5

    name = rubyist.name || ''
    name_font_size = name.size > 14 ? 25 : 30
    namefont = UIFont.fontWithName("AvenirNext-Bold", size: name_font_size)
    name_text_size = name.sizeWithFont(namefont, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    @name.font = namefont
    @name.textColor = UIColor.whiteColor
    @name.backgroundColor = UIColor.clearColor
    @name.text = name
    @name.frame = [[padding, 0], name_text_size]
    addSubview(@name)

    title = rubyist.title || ''
    title_font_size = 16
    begin
      title_font = UIFont.fontWithName("AvenirNext-Medium", size: title_font_size)
      title_font_size -= 1
      break if title_font_size <= 1
      title_text_size = title.sizeWithFont(title_font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
      # XXX: name のサイズが frame より大きかった場合バグる
    end while name_text_size.width + padding * 3 + title_text_size.width > frame.size.width
    @title.font = title_font
    @title.textColor = UIColor.whiteColor
    @title.backgroundColor = UIColor.clearColor
    @title.text = title
    @title.frame = [[name_text_size.width + padding * 2, name_text_size.height - title_text_size.height - padding],
                    title_text_size]
    addSubview(@title)

    second_line_height = name_text_size.height - padding

    bio = rubyist.bio || ''
    bio_font = UIFont.fontWithName("AvenirNext-Medium", size: 16)
    bio_text_size = bio.sizeWithFont(bio_font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    @bio.font = bio_font
    @bio.textColor = UIColor.whiteColor
    @bio.backgroundColor = UIColor.clearColor
    @bio.text = bio
    @bio.frame = [[padding, second_line_height], bio_text_size]
    addSubview(@bio)

    taken_by = "- Photo taken by #{rubyist.taken_by}"
    taken_by_font_size = 14
    begin
      taken_by_font = UIFont.fontWithName("AvenirNext-MediumItalic", size: taken_by_font_size)
      taken_by_font_size -= 1
      break if taken_by_font_size <= 1
      taken_by_text_size = taken_by.sizeWithFont(taken_by_font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
      # XXX: bio のサイズが frame より大きかった場合バグる
    end while bio_text_size.width + padding * 3 + taken_by_text_size.width > frame.size.width
    @taken_by.font = taken_by_font
    @taken_by.textColor = UIColor.whiteColor
    @taken_by.backgroundColor = UIColor.clearColor
    @taken_by.text = taken_by
    @taken_by.frame = [[bio_text_size.width + padding * 2, second_line_height + bio_text_size.height - taken_by_text_size.height],
                    taken_by_text_size]
    addSubview(@taken_by)
  end

  def setNeedsLayout
    if superview
      frame = AVMakeRectWithAspectRatioInsideRect(superview.image.size, superview.bounds);
      origin = frame.origin
      size = frame.size
      origin.y = size.height - textareaHeight
      size.height = textareaHeight

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
