class Default < ActiveRecord::Base
  self.table_name = 'categories'

  default_scope { where('1=1') }

  acts_as_ordered_tree
end

class RenamedColumns < ActiveRecord::Base
  acts_as_ordered_tree :parent_column => :mother_id,
                       :position_column => :red,
                       :depth_column => :pitch

  default_scope { where('1=1') }
end

class DefaultWithCounterCache < ActiveRecord::Base
  self.table_name = 'categories'

  acts_as_ordered_tree :counter_cache => :categories_count

  default_scope { where('1=1') }
end

class DefaultWithoutDepth < ActiveRecord::Base
  self.table_name = 'categories'

  acts_as_ordered_tree :depth_column => false
end

class Scoped < ActiveRecord::Base
  self.table_name = 'scoped'

  default_scope { where('1=1') }

  acts_as_ordered_tree :scope => :scope_type
end

class StiExample < ActiveRecord::Base
  acts_as_ordered_tree :counter_cache => :children_count
end