class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = RubyisTokeiViewController.alloc.init
    @window.rootViewController.wantsFullScreenLayout = true
    @window.makeKeyAndVisible
    # XXX 
    $window = @window
    true
  end
end

class RubyisTokeiViewController < UIViewController
  #def loadView
  #  #self.view = UIImageView.alloc.init
  #  self.view = UIView.alloc.initWithFrame(UIScreen.mainScreen.bounds)
  #end

  #def shouldAutorotateToInterfaceOrientation(orientation)
  #  [
  #   UIInterfaceOrientationLandscapeLeft
  #  ].include?(orientation)
  #end

  def supportedInterfaceOrientations
    UIInterfaceOrientationMaskAll
  end

  attr_accessor :current_rubyist

  def loadView
    @photo = RTPhoto.alloc.initWithFrame([[0,0], UIScreen.mainScreen.bounds.size.to_a.reverse])
    self.view = @photo

    @tokei = RTTokei.new
    view.addSubview @tokei
    @tokei.centering

    RubyistManager.load do |manager|
      @manager = manager
      show_next_rubyist
    end

    #Rubyist.load('kakutani') do |rubyist|
    #  self.current_rubyist = rubyist
    #  @photo.rubyist = rubyist
    #  Rubyist.load('darashi') do |rubyist|
    #    self.current_rubyist = rubyist
    #    @photo.rubyist = rubyist
    #  end
    #end
  end

  def show_next_rubyist
    if @manager
      @manager.next_rubyist do |rubyist|
        @photo.showRubyist rubyist
        @tokei.removeFromSuperview
        @photo.addSubview(@tokei)
        @tokei.updatePositionWithRubyist rubyist
        #@photo.alpha = 0.5
        #UIView.beginAnimations('fadeIn', context: nil)
        #UIView.setAnimationCurve(UIViewAnimationCurveEaseOut)
        #UIView.setAnimationDuration(0.3)
        #@photo.alpha = 1
        #UIView.commitAnimations
        #UIView.beginAnimations('fadeOut', context: nil)
        #UIView.setAnimationCurve(UIViewAnimationCurveEaseOut)
        #UIView.setAnimationDuration(0.3)
        #@photo.alpha = 0.5
        #UIView.commitAnimations
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
    change_15sec?
  end

  def change_15sec?
    Time.now.to_i % 10 == 0
  end

  def change_minute?
    m = Time.now.strftime("%M")
    if m == @last_minute
      false
    else
      @last_minute = m
      true
    end
  end

  def timerFired
    if change_rubyist?
      show_next_rubyist
    end
    @tokei.updateTokeiView
  end
end

class RTTokei < UIView
  CLOCK_FORMAT = "%H %M"

  attr_reader :time_label
  def init
    s = super

    font = UIFont.fontWithName("AvenirNext-Bold", size: 72)
    @text_size = RTTextUtil.text(timeString, sizeWithFont: font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    hour_text_size = RTTextUtil.text("00", sizeWithFont: font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)

    @time_label = UILabel.new
    @time_label.font = font
    @time_label.textAlignment = NSTextAlignmentLeft
    @time_label.textColor = UIColor.whiteColor.colorWithAlphaComponent(0.8)
    @time_label.backgroundColor = UIColor.clearColor
    @time_label.text = timeString
    @time_label.frame = [[0,0], @text_size]
    addSubview(@time_label)

    separator_text_size= RTTextUtil.text(":", sizeWithFont: font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    @separator = UILabel.new
    @separator.font = @time_label.font
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
      size = frame.size
      #<CGRect origin=#<CGPoint x=44.1171264648438 y=0.0> size=#<CGSize width=479.765747070312 height=320.0>>
      origin = frame.origin
      origin.x = (size.width / 1024) * rubyist.left
      origin.y = (size.height / 760) * rubyist.top
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
  def showRubyist(rubyist)
    self.contentMode = UIViewContentModeScaleAspectFit
    if rubyist.image_data
      self.image = UIImage.alloc.initWithData(rubyist.image_data)
      unless @textarea
        @textarea = RTTextarea.new
        addSubview @textarea
      end
      @textarea.renderRubyist rubyist
    end
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

    name = rubyist.name
    name_font = UIFont.fontWithName("AvenirNext-Bold", size: 30)
    name_text_size = RTTextUtil.text(name, sizeWithFont: name_font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    @name.font = name_font
    @name.textColor = UIColor.whiteColor
    @name.backgroundColor = UIColor.clearColor
    @name.text = name
    @name.frame = [[padding, 0], name_text_size]
    addSubview(@name)

    title = rubyist.title
    title_font_size = 16
    begin
      title_font = UIFont.fontWithName("AvenirNext-Medium", size: title_font_size)
      title_font_size -= 1
      break if title_font_size <= 1
      title_text_size = RTTextUtil.text(title, sizeWithFont: title_font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
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

    bio = rubyist.bio
    bio_font = UIFont.fontWithName("AvenirNext-Medium", size: 16)
    bio_text_size = RTTextUtil.text(bio, sizeWithFont: bio_font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
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
      taken_by_text_size = RTTextUtil.text(taken_by, sizeWithFont: taken_by_font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
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
    if false # UIDevice.currentDevice.ios7?
      frame = text.boundingRectWithSize(
        size,
        options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading,
        attributes:self.attributesWithFont(font, color:nil, lineBreakMode:lineBreakMode),
        context:nil
      )
      return CGSizeMake(frame.size.width.ceil, frame.size.height.ceil)
    else
      return text.sizeWithFont(font, constrainedToSize:size, lineBreakMode:lineBreakMode)
    end
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
