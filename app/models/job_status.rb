class JobStatus < ApplicationRecord
  belongs_to :document, optional: true

  enum status: { running: 1, complete: 0, abort: 2 }

  scope :active,    -> { where(status: 1) }
  scope :finished,  -> { where(status: 0) }
  scope :failed,    -> { where(status: 2) }

  def self.clean_up
    where(status: 'running').update_all(status: 'abort')
  end

  def set(status)
    update(status: status)
  end
end
