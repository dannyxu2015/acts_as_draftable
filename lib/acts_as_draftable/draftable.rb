require 'active_support/concern'

module ActsAsDraftable
  module Draftable
    extend ActiveSupport::Concern

    included do

      has_many :drafts, class_name: "ActsAsDraftable::Draft", as: :draftable

      def draft_update(params, owner = nil)
        self.assign_attributes(params)

        unless self.valid?
          raise self.errors.full_messages.join(", ")
        end

        unless self.need_verified_fields.blank?
          draft_check_save(owner)
        else
          draft_all_save(owner)
        end
      end

      def draft_check_save(owner = nil)
        if self.changed?
          draft_res = {}
          no_draft_res = {}
          self.class.column_names.each do |name|
            if self.send("#{name}_changed?")
              if self.need_verified_fields.include? name.to_sym
                draft_res[name] = self.send(name)
              else
                no_draft_res[name] = self.send(name)
              end
            end
          end

          self.reload
          self.update(no_draft_res) unless no_draft_res.blank?

          unless draft_res.blank?
            self.check_draft(draft_res, owner)
          end
        end
      end

      def draft_all_save(owner = nil)
        if self.changed?
          res = {}
          self.class.column_names.each do |name|
            res[name] = self.send(name) if self.send("#{name}_changed?")
          end

          unless res.blank?
            self.check_draft(res, owner)
          end
        end
      end

      def check_draft(draft_res, owner = nil)
        if self.last_draft.blank?
          self.drafts.create(content: draft_res, active: 1, verified: -1, ownerable: owner)
        else
          if self.last_draft.is_waitting_verified?
            return
          elsif self.last_draft.is_editting?
            self.last_draft.update(content: draft_res, active: 1, verified: -1, ownerable: owner)
          else
            self.drafts.create(content: draft_res, active: 1, verified: -1, ownerable: owner)
          end
        end
      end

      def ask_for_verified
        if self.last_draft.is_editting?
          self.last_draft.update(verified: 0)
        else
          return false
        end
      end

      def last_draft
        self.drafts.order(created_at: :desc).first
      end

      def lastest_unverified_draft
        self.drafts.verified_false.first
      end

      def lastest_wait_verified_draft
        self.drafts.wait_verified.first
      end

      def verified_draft_to_true(verfied_mome, operator = nil)
        last_draft.to_online(verfied_mome, operator) if last_draft.present? and last_draft.is_waitting_verified?
      end

      def verified_draft_to_false(verfied_mome, operator = nil)
        last_draft.to_offline(verfied_mome, operator) if last_draft.present? and last_draft.is_waitting_verified?
      end

      def with_draft
        if self.last_active_draft.present?
          self.assign_attributes(self.last_draft.content_as_json)
        end
        self
      end

    end

    module ClassMethods

    end

  end
end