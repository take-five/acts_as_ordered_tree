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

class DefaultWithCallbacks < ActiveRecord::Base
  self.table_name = 'categories'

  acts_as_ordered_tree

  default_scope { where('1=1') }

  after_move     :after_move
  before_move    :before_move
  after_reorder  :after_reorder
  before_reorder :before_reorder

  def after_move; end
  def before_move; end
  def after_reorder; end
  def before_reorder; end
end

class Scoped < ActiveRecord::Base
  self.table_name = 'scoped'

  default_scope { where('1=1') }

  acts_as_ordered_tree :scope => :scope_type
end