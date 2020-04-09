# == Schema Information
#
# Table name: plc_learning_modules
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  plc_course_unit_id :integer          not null
#  module_type        :string(255)
#  stage_id           :integer
#
# Indexes
#
#  index_plc_learning_modules_on_plc_course_unit_id  (plc_course_unit_id)
#  index_plc_learning_modules_on_stage_id            (stage_id)
#

# A component of a course, like "Internet Safety" or "What are loops?"
# Modules are independent of courses. Two people taking the same course may have different modules
# to complete. Additionally, some modules will be part of multiple courses. So courses are not
# part of modules, and modules are not part of courses.
# Learning Modules correspond to Stages in our regular curriculum hierarchy.
class Plc::LearningModule < ActiveRecord::Base
  MODULE_TYPES = [
    REQUIRED_MODULE = 'Overview'.freeze,
    CONTENT_MODULE = 'Content'.freeze,
    PRACTICE_MODULE = 'Teaching Practices'.freeze
  ].freeze

  NONREQUIRED_MODULE_TYPES = (MODULE_TYPES - [REQUIRED_MODULE]).freeze

  attr_readonly :plc_course_unit_id

  belongs_to :stage
  belongs_to :plc_course_unit, class_name: '::Plc::CourseUnit', foreign_key: 'plc_course_unit_id'
  has_many :plc_module_assignments, class_name: '::Plc::EnrollmentModuleAssignment', foreign_key: 'plc_learning_module_id', dependent: :destroy

  validates_presence_of :plc_course_unit_id
  validates_inclusion_of :module_type, in: MODULE_TYPES

  scope :required, -> {where(module_type: REQUIRED_MODULE)}
  scope :content, -> {where(module_type: CONTENT_MODULE)}
  scope :practice, -> {where(module_type: PRACTICE_MODULE)}

  def required?
    module_type == REQUIRED_MODULE
  end
end
