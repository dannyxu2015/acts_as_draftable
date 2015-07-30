module ActsAsDraftable
  class Draft < ::ActiveRecord::Base

    serialize :content

    belongs_to :draftable, :polymorphic => true
    belongs_to :ownerable, :polymorphic => true

    default_scope { order(created_at: :desc) }
    scope :active, -> { where(active: 1) }

    scope :editting, -> { where(verified: -1) }
    scope :verified_false, ->{where(verified: -2)}
    scope :wait_verified, ->{where(verified: 0)}
    scope :verified_true, ->{where(verified: 1)}

    after_create :set_verified


    def unactive
      update(active: 0)
    end

    def active?
      active == 1
    end

    def is_waitting_verified?
      verified == 0
    end

    def is_editting?
      verified == -1
    end

    def to_online(verified_memo, operator)
      self.draftable.update!(self.content_as_json)
      if operator.blank?
        self.update(verified: 1, verified_memo: verified_memo)
      else
        self.update(verified: 1, operater_id: operator.try(:id), verified_memo: verified_memo)
      end
      self.draftable.update(verified: 1)
    end

    def to_offline(verified_memo, operator)
      if operator.blank?
        self.update(verified: -2, verified_memo: verified_memo)
      else
        self.update(verified: -2, operater_id: operator.try(:id), verified_memo: verified_memo)
      end
      self.draftable.update(verified: -2)
    end

    def content_as_json
      self.content.to_h
    end

    def operator_name
      Operator.find(operator_id).try(:name) unless operator_id.blank?
    end


    private
    def set_verified
      self.draftable.update(verified: -1) if self.draftable.respond_to?("verified=")
    end

  end
end