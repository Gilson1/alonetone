require 'bluecloth'
class Update < ActiveRecord::Base
  
  formats_attributes :content
  
  has_permalink :title
  before_save :create_unique_permalink
  
  acts_as_defensio_article(:fields =>{:permalink => :full_permalink})
  
  has_many :comments, :as => :commentable, :dependent => :destroy, :order => 'created_at ASC'
  
  def print
    self.content_html || BlueCloth::new(self.content).to_html
  end
  
    # The following methods help us keep dry w/ comments
  def name
    "blog: #{self.title}"
  end
  
  def full_permalink
    "http://#{ALONETONE.url}/blog/#{permalink}"
  end
  
  alias :unique_id :id  
end
