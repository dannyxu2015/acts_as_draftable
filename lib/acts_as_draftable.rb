require 'active_record'
require 'active_model/dirty'
require "acts_as_draftable/version"

module ActsAsDraftable
  # Your code goes here...

  require 'acts_as_draftable/extenders/extend'
  require 'acts_as_draftable/draft'

  ActiveRecord::Base.extend ActsAsDraftable::Extenders::Extend::Ownerable
  ActiveRecord::Base.extend ActsAsDraftable::Extenders::Extend::Draftable
  ActiveRecord::Base.extend ActsAsDraftable::Extenders::Extend::Tools

end
