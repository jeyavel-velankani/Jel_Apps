class StudentsController < ApplicationController
	before_action :set_student, only: [:show, :destroy]
	require "prawn"
  def new
  	@student = Student.new
  end

  def index
    @students = Student.all
  end

  def show
  	@student = Student.find(params[:id])
  	#Prawn::Document.generate("#{@student.roll_no}.pdf") do
	  respond_to do |format|
      format.html
      format.pdf do
        pdf = ReportPdf.new(@student)
        send_data pdf.render, filename: "report_#{@student.roll_no}.pdf", type: 'application/pdf'
      end
    end
  end

  def delete
  end

  def create
  	puts params.inspect
    @student = Student.new(student_params)
    respond_to do |format|
      if @student.save
        format.html { redirect_to @student, notice: 'Student is successfully created.' }
      else
        format.html { render :new }
      end
    end   
   end

   def edit  
    @student = Student.find(params[:id])
   end

def destroy
    @student.destroy
    respond_to do |format|
      format.html { redirect_to students_url, notice: 'Student is successfully destroyed.' }
      format.json { head :no_content }
    end
end

private

   def set_student
      @student = Student.find(params[:id])
   end

  def student_params
      params.require(:student).permit(:roll_no, :name, :blood_group, :department, :image)
  end

end

