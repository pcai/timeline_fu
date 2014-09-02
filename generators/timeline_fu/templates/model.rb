class TimelineEvent < ActiveRecord::Base
  attr_accessible :event, :actor, :subject, :secondary_subject,
                  :event_type, :actor_type, :subject_type, :secondary_subject_type

  belongs_to :actor,              polymorphic: true
  belongs_to :subject,            polymorphic: true
  belongs_to :secondary_subject,  polymorphic: true
end
