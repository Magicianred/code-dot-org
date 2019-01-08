require 'test_helper'

module Pd::Application
  class Facilitator1920ApplicationTest < ActiveSupport::TestCase
    include Pd::Application::ApplicationConstants
    include Pd::Facilitator1920ApplicationConstants

    self.use_transactional_test_case = true
    setup_all do
      @regional_partner = create :regional_partner
      @fit_workshop = create :pd_workshop, :fit
      @workshop = create :pd_workshop
      @application = create :pd_facilitator1920_application
      @application_with_fit_workshop = create :pd_facilitator1920_application,
        pd_workshop_id: @workshop.id, fit_workshop_id: @fit_workshop.id
    end
    setup do
      @application.reload
      @application_with_fit_workshop.reload
    end

    test 'course is filled in from the form program before validation' do
      [:csf, :csd, :csp].each do |program|
        application_hash = build :pd_facilitator1920_application_hash_common, program
        application = build :pd_facilitator1920_application, form_data_hash: application_hash
        assert application.valid?, "Errors in #{program} application: #{application.errors.full_messages}"
        assert_equal program.to_s, application.course
      end
    end

    test 'match regional partner' do
      # match
      RegionalPartner.expects(:find_by_region).with('11111', 'WA').returns(@regional_partner)
      application_hash = build :pd_facilitator1920_application_hash, zip_code: '11111', state: 'Washington'
      application_with_match = create :pd_facilitator1920_application, form_data_hash: application_hash
      assert_equal @regional_partner, application_with_match.regional_partner

      # No match
      RegionalPartner.expects(:find_by_region).with('22222', 'WA').returns(nil)
      application_hash = build :pd_facilitator1920_application_hash, zip_code: '22222', state: 'Washington'
      application_without_match = create :pd_facilitator1920_application, form_data_hash: application_hash
      assert_nil application_without_match.regional_partner
    end

    test 'matched regional partner is not overridden by later form data' do
      RegionalPartner.expects(:find_by_region).never
      application = create :pd_facilitator1920_application, regional_partner: @regional_partner

      application.form_data = build(:pd_facilitator1920_application_hash)
      assert_equal @regional_partner, application.regional_partner
    end

    test 'open until Feb 1, 2019' do
      Timecop.freeze Time.zone.local(2019, 1, 31, 23, 59) do
        assert Facilitator1920Application.open?
      end
      Timecop.freeze Time.zone.local(2019, 2, 1) do
        refute Facilitator1920Application.open?
      end
    end

    test 'only one application allowed per user' do
      e = assert_raises ActiveRecord::RecordInvalid do
        create :pd_facilitator1920_application, user: @application.user
      end
      assert_equal 'Validation failed: User has already been taken', e.message
    end

    test 'state_code and state_name' do
      application_hash = build :pd_facilitator1920_application_hash, state: 'Washington'
      application = build :pd_facilitator1920_application, form_data_hash: application_hash
      assert_equal 'Washington', application.state_name
      assert_equal 'WA', application.state_code
    end

    test 'answer_with_additional_text with defaults' do
      application_hash = build :pd_facilitator1920_application_hash
      application_hash[:institution_type] = ['School district', 'Other:']
      application_hash[:institution_type_other] = 'School of Witchcraft and Wizardry'

      assert_equal(
        [
          'School district',
          'Other: School of Witchcraft and Wizardry'
        ],
        Facilitator1920Application.answer_with_additional_text(application_hash, :institution_type)
      )
    end

    test 'answer_with_additional_text with custom field' do
      OPTION = 'A Code.org Regional Partner (please share name):'
      application_hash = build :pd_facilitator1920_application_hash
      application_hash[:how_heard] = [OPTION]
      application_hash[:how_heard_regional_partner] = 'Hogwarts Coding Wizards'

      assert_equal(
        [
          "#{OPTION} Hogwarts Coding Wizards"
        ],
        Facilitator1920Application.answer_with_additional_text(application_hash, :how_heard, OPTION, :how_heard_regional_partner)
      )
    end

    test 'csf applications have csd-csp answers filtered out' do
      application_hash = build :pd_facilitator1920_application_hash,
        :with_csf_specific_fields, :with_csd_csp_specific_fields,
        program: Facilitator1920Application::PROGRAMS[:csf]
      application = build :pd_facilitator1920_application, form_data_hash: application_hash, course: :csf

      answers = application.full_answers
      [
        :csf_good_standing_requirement,
        :csf_summit_requirement,
        :csf_workshop_requirement,
        :csf_community_requirement
      ].each {|x| assert answers.key? x}
      [
        :csd_csp_lead_summer_workshop_requirement,
        :csd_csp_workshop_requirement,
        :csd_csp_lead_summer_workshop_requirement,
        :csd_csp_deeper_learning_requirement
      ].each {|x| refute answers.key? x}
    end

    test 'csd and csp applications have csf answers filtered out' do
      [:csd, :csp].each do |course|
        application_hash = build :pd_facilitator1920_application_hash,
          :with_csf_specific_fields, :with_csd_csp_specific_fields,
          program: Facilitator1920Application::PROGRAMS[course]
        application = build :pd_facilitator1920_application, form_data_hash: application_hash, course: course

        answers = application.full_answers

        [
          :csf_good_standing_requirement,
          :csf_summit_requirement,
          :csf_workshop_requirement,
          :csf_community_requirement
        ].each {|x| refute answers.key? x}
        [
          :csd_csp_lead_summer_workshop_requirement,
          :csd_csp_workshop_requirement,
          :csd_csp_lead_summer_workshop_requirement,
          :csd_csp_deeper_learning_requirement
        ].each {|x| assert(answers.key?(x), "Expected #{x} to be in the hash")}
      end
    end

    test 'to_csv_row method' do
      @application.update!(regional_partner: @regional_partner, status: 'accepted', notes: 'notes')

      csv_row = @application.to_csv_row(nil)
      csv_answers = csv_row.split(',')
      assert_equal "#{@regional_partner.name}\n", csv_answers[-1]
      assert_equal 'notes', csv_answers[-13]
      assert_equal 'false', csv_answers[-14]
      assert_equal 'accepted', csv_answers[-15]
    end

    test 'csv_header and row return same number of columns' do
      mock_user = mock

      header = Facilitator1920Application.csv_header('csp', mock_user)
      row = @application.to_csv_row(mock_user)
      assert_equal CSV.parse(header).length, CSV.parse(row).length,
        "Expected header and row to have the same number of columns"
    end

    test 'to_cohort_csv' do
      optional_columns = {registered_workshop: true, accepted_teachercon: false}
      assert (header = Facilitator1920Application.cohort_csv_header(optional_columns))
      assert (row = @application.to_cohort_csv_row(optional_columns))
      assert_equal CSV.parse(header).length, CSV.parse(row).length,
        "Expected header and row to have the same number of columns"
    end

    test 'locking an application with fit_workshop_id automatically enrolls user' do
      @application.fit_workshop_id = @fit_workshop.id
      @application.status = "accepted"

      assert_creates(Pd::Enrollment) do
        @application.lock!
      end
      assert_equal Pd::Enrollment.last.workshop, @fit_workshop
      assert_equal Pd::Enrollment.last.id, @application.auto_assigned_fit_enrollment_id
    end

    test 'updating and re-locking an application with an auto-assigned FIT enrollment will delete old enrollment' do
      first_workshop = @fit_workshop
      second_workshop = create :pd_workshop, :fit

      @application.fit_workshop_id = first_workshop.id
      @application.status = "accepted"
      @application.lock!

      first_enrollment = Pd::Enrollment.find(@application.auto_assigned_fit_enrollment_id)

      @application.unlock!
      @application.fit_workshop_id = second_workshop.id
      @application.lock!

      assert first_enrollment.reload.deleted?
      assert_not_equal first_enrollment.id, @application.auto_assigned_fit_enrollment_id
    end

    test 'upading the application to unaccepted will also delete the autoenrollment' do
      @application.fit_workshop_id = @fit_workshop.id
      @application.status = "accepted"
      @application.lock!
      first_enrollment = Pd::Enrollment.find(@application.auto_assigned_fit_enrollment_id)

      @application.unlock!
      @application.status = "waitlisted"
      @application.lock!

      assert first_enrollment.reload.deleted?

      @application.unlock!
      @application.status = "accepted"

      assert_creates(Pd::Enrollment) do
        @application.lock!
      end

      assert_not_equal first_enrollment.id, @application.auto_assigned_fit_enrollment_id
    end

    test 'assign_default_workshop! saves the default workshop' do
      @application.expects(:find_default_workshop).returns(@fit_workshop)

      @application.assign_default_workshop!
      assert_equal @fit_workshop.id, @application.reload.pd_workshop_id
    end

    test 'assign_default_workshop! does nothing when a workshop is already assigned' do
      @application.update! pd_workshop_id: @fit_workshop.id
      @application.expects(:find_default_workshop).never

      @application.assign_default_workshop!
      assert_equal @fit_workshop.id, @application.reload.pd_workshop_id
    end

    test 'assign_default_fit_workshop! saves the default fit workshop' do
      @application.expects(:find_default_fit_workshop).returns(@fit_workshop)

      @application.assign_default_fit_workshop!
      assert_equal @fit_workshop.id, @application.reload.fit_workshop_id
    end

    test 'assign_default_fit_workshop! does nothing when a fit workshop is already assigned' do
      @application_with_fit_workshop.expects(:find_default_fit_workshop).never

      @application_with_fit_workshop.assign_default_fit_workshop!
      assert_equal @fit_workshop.id, @application_with_fit_workshop.reload.fit_workshop_id
    end

    test 'fit_workshop returns the workshop associated with the assigned fit workshop id' do
      assert_equal @fit_workshop, @application_with_fit_workshop.fit_workshop
    end

    test 'fit_workshop returns nil if the assigned workshop has been deleted' do
      @fit_workshop.destroy!
      assert_nil @application_with_fit_workshop.fit_workshop
    end

    test 'registered_fit_workshop? returns true when the applicant is enrolled in the assigned fit workshop' do
      create :pd_enrollment, workshop: @fit_workshop, user: @application_with_fit_workshop.user
      assert @application_with_fit_workshop.registered_fit_workshop?
    end

    test 'registered_fit_workshop? returns false when the applicant is not enrolled in the assigned fit workshop' do
      refute @application_with_fit_workshop.registered_fit_workshop?
    end

    test 'registered_fit_workshop? returns false when no fit workshop is assigned' do
      @application_with_fit_workshop.update! fit_workshop_id: nil
      refute @application_with_fit_workshop.registered_fit_workshop?
    end

    test 'workshop cache' do
      create :pd_enrollment, workshop: @fit_workshop, user: @application_with_fit_workshop.user

      # Original query: Workshop, Session, Enrollment
      assert_queries 3 do
        assert_equal @fit_workshop, @application_with_fit_workshop.fit_workshop
      end

      # Cached
      assert_queries 0 do
        assert_equal @fit_workshop, @application_with_fit_workshop.fit_workshop
        assert @application_with_fit_workshop.registered_fit_workshop?
      end
    end

    test 'workshop cache prefetch' do
      # Workshop, Session, Enrollment
      assert_queries 3 do
        Facilitator1920Application.prefetch_associated_models([@application_with_fit_workshop])
      end

      assert_queries 0 do
        assert_equal @fit_workshop, @application_with_fit_workshop.fit_workshop

        # also prefetches assigned workshop
        assert_equal @workshop, @application_with_fit_workshop.workshop
      end
    end

    test 'fit_cohort' do
      skip "update when 1920 fit registration is implemented"
      included = [
        create(:pd_facilitator1920_application, :locked, fit_workshop_id: @fit_workshop.id, status: :accepted),
        create(:pd_facilitator1920_application, :locked, fit_workshop_id: @fit_workshop.id, status: :waitlisted)
      ]

      excluded = [
        # not locked
        create(:pd_facilitator1920_application, fit_workshop_id: @fit_workshop.id, status: :accepted),

        # not accepted or waitlisted
        @application_with_fit_workshop,

        # no workshop
        @application
      ]

      fit_cohort = Facilitator1920Application.fit_cohort

      included.each do |application|
        assert fit_cohort.include? application
      end
      excluded.each do |application|
        refute fit_cohort.include? application
      end
    end

    test 'memoized filtered_labels' do
      Facilitator1920Application::FILTERED_LABELS.clear

      filtered_labels_csd = Facilitator1920Application.filtered_labels('csd')
      assert filtered_labels_csd.key? :csd_csp_lead_summer_workshop_requirement
      refute filtered_labels_csd.key? :csf_good_standing_requirement
      assert_equal ['csd'], Facilitator1920Application::FILTERED_LABELS.keys

      filtered_labels_csf = Facilitator1920Application.filtered_labels('csf')
      refute filtered_labels_csf.key? :csd_csp_lead_summer_workshop_requirement
      assert filtered_labels_csf.key? :csf_good_standing_requirement
      assert_equal ['csd', 'csf'], Facilitator1920Application::FILTERED_LABELS.keys
    end

    test 'meets_criteria says yes if everything is set to YES, no if anything is NO, and INCOMPLETE if anything is unset' do
      %w(csf csd csp).each do |course|
        application = create :pd_facilitator1920_application, course: course
        score_hash = SCOREABLE_QUESTIONS["criteria_score_questions_#{course}".to_sym].map {|key| [key, YES]}.to_h

        application.update(
          response_scores: {meets_minimum_criteria_scores: score_hash}.to_json
        )

        assert_equal YES, application.meets_criteria

        application.update(
          response_scores: {meets_minimum_criteria_scores: score_hash.merge({teaching_experience: NO})}.to_json
        )

        assert_equal NO, application.meets_criteria

        application.update(
          response_scores: {meets_minimum_criteria_scores: score_hash.merge({teaching_experience: nil})}.to_json
        )

        assert_equal REVIEWING_INCOMPLETE, application.meets_criteria
      end
    end

    test 'scoring works as expected' do
      @application.update(
        response_scores: @application.default_response_score_hash.deep_merge(
          {
            bonus_points_scores: {
              currently_involved_in_cs_education: 5,
              grades_taught: 5,
              experience_teaching_this_course: 5,
              completed_pd: 5,
              why_should_all_have_access: 5,
              skills_areas_to_improve: 5,
              inquiry_based_learning: 5,
              why_interested: 5,
              question_1: 5,
              question_2: 5,
              question_3: 5,
              question_4: 5,
              question_5: 5
            }
          }
        ).to_json
      )

      assert_equal(
        {
          total_score: "65 / 65",
          application_score: "40 / 40",
          interview_score: "25 / 25",
          teaching_experience_score: "10 / 10",
          leadership_score: "5 / 5",
          champion_for_cs_score: "5 / 5",
          equity_score: "15 / 15",
          growth_minded_score: "15 / 15",
          content_knowledge_score: "10 / 10",
          program_commitment_score: "5 / 5"
        }, @application.all_scores
      )
    end
  end
end
