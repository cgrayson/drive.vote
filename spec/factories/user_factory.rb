FactoryGirl.define do

  factory :user do
    name 'Jamie Farr'
    sequence(:email) { |n| "james#{n}@example.com" }
    password '123456789'
    city 'Toledo'
    state 'Oh'
    zip '43601'
    sequence(:phone_number) { |n| "510-555-%04d" % n}

    factory :admin_user do
      user_type :admin
    end

    factory :driver_user do
      user_type :driver
    end

    factory :dispatcher_user do
      transient do
        rz { create( :ride_zone ) }
      end

      after(:create) do |user, evaluator|
        user.add_role( :dispatcher, evaluator.rz )
      end
    end

    factory :zoned_driver_user do
      transient do
        rz { create( :ride_zone ) }
      end

      after(:create) do |user, evaluator|
        user.add_role( :driver, evaluator.rz)
      end
    end

    factory :unassigned_driver_user do
      user_type :unassigned_driver
    end

    factory :voter_user do
      transient do
        rz { create( :ride_zone ) }
      end

      user_type :voter
      locale :en

      after(:create) do |user, evaluator|
        user.add_role( :voter, evaluator.rz)
      end

      factory :sms_voter_user do
        phone_number '+15555551234'
        name User.sms_name('+15555551234')
      end
    end
  end
end
