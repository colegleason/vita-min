module Questions
  class StudentController < QuestionsController
    layout "yes_no_question"

    private

    def method_name
      "had_student_in_family"
    end
  end
end
