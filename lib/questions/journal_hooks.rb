module Questions
  class JournalHooks < HooksBase
    
    
    def view_journals_notes_form_after_notes(context = { })
      @journal = context[:journal]
      if @journal.question && @journal.question.opened
        # Allow the Remove option and no blank option
        options = [[l(:text_question_remove), :remove]] + [[l(:text_anyone), :anyone]] + (@journal.issue.assignable_users.collect {|m| [m.name, m.id]})
        selected = @journal.question.assigned_to.id
        blank = false
      else
        # No Remove option but a blank option
        options = [[l(:text_anyone), :anyone]] + (@journal.issue.assignable_users.collect {|m| [m.name, m.id]})
        selected = nil
        blank = true
      end
      
      
      
      o = ''
      o << content_tag(:p, 
                       ("<label>#{l(:field_question_assign_to_id)}</label> " + 
                       select(:question,
                              :assigned_to_id,
                              options,
                              :selected => selected,
                              :include_blank => blank )).html_safe)
      return o
    end
    
    def controller_journals_edit_post(context = { })
      journal = context[:journal]
      params = context[:params]
  
      if params[:question] && !params[:question][:assigned_to_id].blank?
  
        if journal.question && params[:question][:assigned_to_id] == 'remove'
          # Wants to remove the question
          journal.question.destroy
        elsif journal.question && journal.question.opened
          # Reassignment
          journal.question.update_attributes(:assigned_to_id => params[:question][:assigned_to_id])
        elsif journal.question && !journal.question.opened
          # Existing question, destry it first and then add a new question
          journal.question.destroy
          add_new_question(journal, params[:question][:assigned_to_id])
        else
          add_new_question(journal, params[:question][:assigned_to_id])
        end
  
      end
      
      return ''
    end
    
    def view_journals_update_rjs_bottom(context = { })
      @journal = context[:journal]
      page = context[:page]
      unless @journal.frozen?
        @journal.reload
        if @journal && @journal.question && @journal.question.opened?
          question = @journal.question
        
          if question.assigned_to
            html = assigned_question_html(question)
          else
            html = unassigned_question_html(question)
          end
  
          page << "$('#change-#{@journal.id}').addClass('question');"
          page << "$('#change-#{@journal.id} h4 span.question-line').each(function(ele) {ele.remove()});"
          page << "$('#change-#{@journal.id} h4 a:first').after(' #{html} ' );"
        
        elsif @journal && @journal.question.nil?
          # No question found, make sure the UI reflects this
          page << "$('change-#{@journal.id}').removeClass('question');"
          page << "$('#change-#{@journal.id} h4 span.question-line').each(function(ele) {ele.remove()});"
        end
      end
      return ''
    end
    
    private
    
    def add_new_question(journal, assigned_to)
      journal.question = Question.new(
                                      :author => User.current,
                                      :issue => journal.issue
                                      )
      if assigned_to != 'anyone'
        # Assigned to a specific user
        journal.question.assigned_to = User.find(assigned_to.to_i)
      end
      journal.question.save!
      journal.save
    end
  end
end