# Read input from STDIN. Print your output to STDOUT

def main()

	# Write code here
	#Day1
	# get_stdio_val = gets
	# puts "Hello Techgig"
	# puts get_stdio_val
    get_stdio_val = gets
    puts get_stdio_val.match(/\A[+-]?\d+?(_?\d+)*(\.\d+e?\d*)?\Z/)
    if get_stdio_val.match(/\A[+-]?\d+?(_?\d+)*(\.\d+e?\d*)?\Z/)
    	puts "This input is of type Integer."
	elsif Float === get_stdio_val.to_f
		puts "This input is of type Float."
	elsif String === get_stdio_val.to_s
		puts "This input is of type #{get_stdio_val.class}."
	else
		puts "This is somthing else."
	end
end
main()
