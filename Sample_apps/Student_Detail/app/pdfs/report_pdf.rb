class ReportPdf < Prawn::Document
  def initialize(student)
    super()
    @student = student
    bounding_box([0, 500], :width => 200, :height => 350) do
    	stroke_color  "0000FF"
    	stroke_bounds
       	image "#{Rails.root}/public/images/std.JPG", width: 150, height: 150, position: :center
    	text "SCHOOL_NAME",size: 15, style: :bold, align: :center
    	index_val = "#{@student.image.url(:med)}".index("?") - 1
    	path = "#{@student.image.url(:med)}"[0..index_val]
    	image "#{Rails.root}/public#{path}", position: :center
        text "\n#{@student.name.upcase}",size: 13, style: :bold, align: :center
        text "Roll No:#{@student.roll_no} \n Blood Group: #{@student.blood_group} \n Department:#{@student.department}", size: 12, align: :center
        #data = [["Roll No",":","#{@student.roll_no}"],
    	#		["Blood Group",":" ,"#{@student.blood_group}"],
    	#	    ["Department",":","#{@student.department}"]]
        #table(data)
    end
  end
 end