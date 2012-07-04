class Default < ActiveRecord::Base
  self.table_name = "categories"

  acts_as_ordered_tree
end

class RenamedColumns < ActiveRecord::Base
  acts_as_ordered_tree :parent_column => :mother_id,
                       :position_column => :red,
                       :depth_column => :pitch
end

class DefaultWithCounterCache < ActiveRecord::Base
  self.table_name = "categories"

  acts_as_ordered_tree :counter_cache => :categories_count
end