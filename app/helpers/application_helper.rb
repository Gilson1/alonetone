# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  @@listen_sources = %w(itunes home download facebook)

  def authorized_for(user_related_record)
    logged_in? && (current_user.admin? || (user_related_record.user == current_user))
  end
  
  def authorized_as(user_account)
    logged_in? && ((current_user.id.to_s == user_account.id.to_s) || current_user.admin?)
  end
  
  def authorized_for_comment(comment)
    (moderator? || admin?) || (logged_in? && (comment.commenter == current_user || comment.user == current_user))
  end
  
  def edit_or_show(user, playlist)
    if authorized_for(playlist)
      edit_user_playlist_path(@user.login, playlist)
    else
      user_playlist_path(@user.login, playlist.permalink)
    end
  end
  
  def mp3_info_for(asset)
    mp3 = Mp3Info::Mp3Info.new(asset.authenticated_s3_url)
    "Filename: #{asset.permalink}<br/>Length: #{mp3.length}<br/>Name: #{mp3.tag.title}<br/>Artist: #{mp3.tag.artist} <br/>Album: #{mp3.tag.album}<br/>#{mp3.to_s}"
  rescue
    "File #{asset.permalink} was unopenable or did not exist."
  end
  
  def offer(html)
    result = '<div id="offer">'
    result += html
    result += '</div>'
    result
  end
  
  def rss_date(date)
    CGI.rfc1123_date(date)
  end
  

  
  def track_name_for(asset, length=40)
    truncate(h(asset.name),:length => length)
  end
  
  # Awesome truncate
  # First regex truncates to the length, plus the rest of that word, if any.
  # Second regex removes any trailing whitespace or punctuation (except ;).
  # Unlike the regular truncate method, this avoids the problem with cutting
  # in the middle of an entity ex.: truncate("this &amp; that",9)  => "this &am..."
  # though it will not be the exact length.
  def awesome_truncate(text, length = 30, truncate_string = "...")
    return if text.blank?
    l = length - truncate_string.mb_chars.length
    text.mb_chars.length > length ? text[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
  end

  def link_to_play(asset, referer=nil)
    link_to ' ', user_track_path(asset.user.login, asset.permalink, :format => :mp3, :referer => referer), :id=>"play-#{asset.unique_id}", :class => 'play_link', :title => 'click to play the mp3'
  end
  
  def user_nav_item(text, link, options=nil)
    added_class = options.delete(:added_class) if options.is_a? Hash
    content_tag(:li, link_to_unless_current(text, link, options),:class=> ("#{added_class} #{"current" if current_page?(link)}"))
  end
  
  def link_source(source)
    return source if @@listen_sources.include?(source) || source == 'alonetone' || source == 'unknown' || source == 'direct hit'
    return link_to('alonetone home', root_path) if source == 'home'
    return link_to('ListenApp!', 'http://listenapp.com') if source.include?('listenapp')
    link_to source.gsub!(/http:\/\/alonetone.com\/|http:\/\/localhost:3000\/|http:\/\/staging.alonetone.com\//, ''), source
  end
  
  def recently_online
    @online.each {|person| link_to person.login, user_home_path(person) }
  end
  
  def check_for_and_display_flashes
    flashes = []
    [flash[:notice], flash[:error], flash[:info], flash[:ok]].each do |flash|
      flashes << (render :partial => 'shared/flash', :object => flash) if (flash && !flash.empty?)
    end
    flashes.join
  end
  
  def check_for_and_display_welcome_back
    render :partial => 'shared/welcome_back' if welcome_back?
  end
  
  def authorized?
    admin? || @user === current_user 
  end
  
  def notice_for(notice, h1_text, &block)
    concat content_tag(:div, ((content_tag :h1, h1_text, :class => 'notice') + 
      hide_notice_link(notice) + 
      capture(&block)), :class => 'notice'),
      block.binding unless notice_hidden?(notice)
  end
  
  def hide_notice_link(notice)
    link_to ['Ok, hide this notice', 'Yup! all good, thanks'].rand, 
      user_path(current_user, :user =>{:settings => {:hide_notice => {notice => true}}}, :method => :put),
      :class => 'hide_notice' if logged_in?
  end
  
  def login_link
    logged_in? ? '' : '('+(link_to 'login', login_path)+')'
  end
  
  def feed_icon_tag(title, url)
    (@feed_icons ||= []) << { :url => url, :title => title }
    link_to image_tag('feed-icon.png', :size => '14x14', :alt => "Subscribe to #{title}"), url, :class => 'rss'
  end  
  
  def friendly_time_ago(time)
    if time > 1.week.ago 
      time_ago_in_words(time) + ' ago'
    else
      time.to_date.to_s(:long)
    end  
  end
  
  # Mephisto said it best...
  def sanitize_feed_content(html, sanitize_tables = false)
    options = sanitize_tables ? {} : {:tags => %w(table thead tfoot tbody td tr th)}
    returning h(html.strip) do |html|
      html.gsub! /&amp;(#\d+);/ do |s|
        "&#{$1};"
      end
    end
  end
  protected 
end
