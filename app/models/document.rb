class Document < ApplicationRecord
  has_many :job_statuses, dependent: :destroy

  validates :name, uniqueness: true

  scope :processed, -> { joins(:job_statuses).merge(JobStatus.finished) }

end
