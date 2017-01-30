#	Copyright (c) 2007 Greg Willits
#	Version	1.0	* 2007-12-11
#	
#	Unless noted specifically, all plugins in this repository are MIT licensed:
#	
#	Permission is hereby granted, free of charge, to any person obtaining a copy of 
#	this software and associated documentation files (the "Software"), to deal in 
#	the Software without restriction, including without limitation the rights to 
#	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of 
#	the Software, and to permit persons to whom the Software is furnished to do so, 
#	subject to the following conditions:
#	
#	The above copyright notice and this permission notice shall be included in all 
#	copies or substantial portions of the Software.
#	
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
#	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
#	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
#	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
#	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#	thanks to this blog entry for its examples:
#	http://www.marklunds.com/articles/one/312


module ActiveRecord
    module Validations
        module ClassMethods

#------------------------------------------------------------

oct200 = "\303\200"
oct226 = "\303\226"
oct231 = "\303\231"
oct266 = "\303\266"
oct271 = "\303\271"
oct277 = "\303\277"

utf_accents						= "#{oct200}-#{oct226}#{oct231}-#{oct266}#{oct271}-#{oct277}"

@@is_not_from_options_msg		= 'has a value other than the valid options below'

@@is_required_msg				= 'cannot be empty'
@@is_required					= /.+/

@@is_person_name_msg 			= 'accepts only letters, hyphens, spaces, apostrophes, and periods'
@@is_person_name				= /^[a-zA-Z#{utf_accents}\.\'\-\ ]*?$/u

@@is_business_name_msg 			= 'accepts only letters, 0-9, hyphens, spaces, apostrophes, commas, and periods'
@@is_business_name				= /^[a-zA-Z0-9#{utf_accents}\.\'\-\,\ ]*?$/u

@@is_street_address_msg			= 'accepts only letters, 0-9, hyphens, spaces, apostrophes, commas, periods, and number signs'
@@is_street_address				= /^[a-zA-Z0-9#{utf_accents}\.\'\-\,\#\ ]*?$/u

@@is_alpha_msg					= 'accepts only letters'
@@is_alpha						= /^[a-zA-Z#{utf_accents}]*?$/u

@@is_alpha_space_msg 			= 'accepts only letters and spaces'
@@is_alpha_space				= /^[a-zA-Z#{utf_accents}\ ]*?$/u

@@is_alpha_hyphen_msg 			= 'accepts only letters and hyphens'
@@is_alpha_hyphen				= /^[a-zA-Z#{utf_accents}\-]*?$/u

@@is_alpha_underscore_msg 		= 'accepts only letters and underscores'
@@is_alpha_underscore			= /^[a-zA-Z#{utf_accents}\_]*?$/u

@@is_alpha_symbol_msg			= 'accepts only letters and !@#$%^&*'
@@is_alpha_symbol				= /^[a-zA-Z#{utf_accents}\!\@\#\$\%\^\&\*]*?$/u

@@is_alpha_separator_msg		= 'accepts only letters, underscores, hyphens, and spaces'
@@is_alpha_separator			= /^[a-zA-Z#{utf_accents}\_\-\ ]*?$/u

@@is_alpha_numeric_msg			= 'accepts only letters and 0-9'
@@is_alpha_numeric				= /^[a-zA-Z0-9#{utf_accents}]*?$/u

@@is_alpha_numeric_space_msg	= 'accepts only letters, 0-9, and spaces'
@@is_alpha_numeric_space		= /^[a-zA-Z0-9#{utf_accents}\ ]$/

@@is_alpha_numeric_underscore_msg	= 'accepts only letters, 0-9, and underscores'
@@is_alpha_numeric_underscore		= /^[a-zA-Z0-9#{utf_accents}\_]*?$/u

@@is_alpha_numeric_hyphen_msg	= 'accepts only letters, 0-9, and hyphens'
@@is_alpha_numeric_hyphen		= /^[a-zA-Z0-9#{utf_accents}\-]*?$/u

@@is_alpha_numeric_symbol_msg	= 'accepts only letters, 0-9, and !@#$%^&*'
@@is_alpha_numeric_symbol		= /^[a-zA-Z0-9#{utf_accents}\!\@\#\$\%\^\&\*]*?$/u

@@is_alpha_numeric_separator_msg	= 'accepts only letters, 0-9, underscore, hyphen, and space'
@@is_alpha_numeric_separator		= /^[a-zA-Z0-9#{utf_accents}\_\-\ ]*?$/u

@@is_numeric_msg				= 'accepts only numeric characters (0-9)'
@@is_numeric					= /^[0-9]*?$/

@@is_decimal_msg				= 'accepts only numeric characters, period, and negative sign (no commas, requires at least .0)'
@@is_decimal					= /^-{0,1}\d*\.{0,1}\d+$/

@@is_positive_decimal_msg		= 'accepts only numeric characters and period (no commas, requires at least .0)'
@@is_positive_decimal			= /^\d*\.{0,1}\d+$/

@@is_integer_msg				= 'accepts only numeric characters, and negative sign (no commas)'
@@is_integer					= /^-{0,1}\d+$/

@@is_positive_integer_msg		= 'accepts positive integer only (no commas)'
@@is_positive_intger			= /^\d+$/

@@is_email_address_msg			= 'must contain an @ symbol, at least one period after the @, and one A-Z letter in each segment'
@@is_email_address				= /^[A-Z0-9._%-]+@[A-Z0-9._%-]+\.[A-Z]{2,4}$/i

#------------------------------------------------------------
def do_as_format_of(attr_names, configuration)
	configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
	if configuration.has_key?(:label)
		msg_string = "The field <span class=\"inputErrorFieldName\">#{configuration[:label]}</span> #{configuration[:message]}."
	else
		msg_string = "This field #{configuration[:message]}"
	end
	configuration.store(:message, msg_string)
	configuration.delete(:label)
	validates_format_of attr_names, configuration
end

#------------------------------------------------------------
def do_as_inclusion_of(attr_names, configuration)
	configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
	if configuration.has_key?(:label)
		msg_string = "The field <span class=\"inputErrorFieldName\">#{configuration[:label]}</span> #{configuration[:message]}."
	else
		msg_string = "This field #{configuration[:message]}"
	end
	configuration.store(:message, msg_string)
	configuration.delete(:label)
	validates_inclusion_of attr_names, configuration
end

#------------------------------------------------------------
def validates_as_required(*attr_names)
	configuration = {
		:message   => @@is_required_msg,
		:with      => @@is_required }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_person_name(*attr_names)
	configuration = {
		:message   => @@is_person_name_msg,
		:with      => @@is_person_name }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_business_name(*attr_names)
	configuration = {
		:message   => @@is_business_name_msg,
		:with      => @@is_business_name }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_street_address(*attr_names)
	configuration = {
		:message   => @@is_street_address_msg,
		:with      => @@is_street_address_msg }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha(*attr_names)
	configuration = {
		:message   => @@is_alpha_msg,
		:with      => @@is_alpha }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha_space(*attr_names)
	configuration = {
		:message   => @@is_alpha_space_msg,
		:with      => @@is_alpha_space }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha_hyphen(*attr_names)
	configuration = {
		:message   => @@is_alpha_hyphen_msg,
		:with      => @@is_alpha_hyphen }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha_underscore(*attr_names)
	configuration = {
		:message   => @@is_alpha_underscore_msg,
		:with      => @@is_alpha_underscore }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha_symbol(*attr_names)
	configuration = {
		:message   => @@is_alpha_symbol_msg,
		:with      => @@is_alpha_symbol }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha_separator(*attr_names)
	configuration = {
		:message   => @@is_alpha_separator_msg,
		:with      => @@is_alpha_separator }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha_numeric(*attr_names)
	configuration = {
		:message   => @@is_alpha_numeric_msg,
		:with      => @@is_alpha_numeric }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha_numeric_space(*attr_names)
	configuration = {
		:message   => @@is_alpha_numeric_space_msg,
		:with      => @@is_alpha_numeric_space }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha_numeric_hyphen(*attr_names)
	configuration = {
		:message   => @@is_alpha_numeric_hyphen_msg,
		:with      => @@is_alpha_numeric_hyphen }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha_numeric_underscore(*attr_names)
	configuration = {
		:message   => @@is_alpha_numeric_underscore_msg,
		:with      => @@is_alpha_numeric_underscore }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha_numeric_symbol(*attr_names)
	configuration = {
		:message   => @@is_alpha_numeric_symbol_msg,
		:with      => @@is_alpha_numeric_symbol }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_alpha_numeric_separator(*attr_names)
	configuration = {
		:message   => @@is_alpha_numeric_separator_msg,
		:with      => @@is_alpha_numeric_separator }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_numeric(*attr_names)
	configuration = {
		:message   => @@is_numeric_msg,
		:with      => @@is_numeric }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_decimal(*attr_names)
	configuration = {
		:message   => @@is_decimal_msg,
		:with      => @@is_decimal }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_positive_decimal(*attr_names)
	configuration = {
		:message   => @@is_positive_decimal_msg,
		:with      => @@is_positive_decimal }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_integer(*attr_names)
	configuration = {
		:message   => @@is_integer_msg,
		:with      => @@is_integer }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_positive_integer(*attr_names)
	configuration = {
		:message   => @@is_positive_integer_msg,
		:with      => @@is_positive_integer }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_email(*attr_names)
	configuration = {
		:message   => @@is_email_address_msg,
		:with      => @@is_email_address }
	do_as_format_of(attr_names, configuration)
end

#------------------------------------------------------------
def validates_as_value_list(*attr_names)
	configuration = {
		:message => @@is_not_from_options_msg }
	do_as_inclusion_of(attr_names, configuration)
end

#------------------------------------------------------------

		end
	end
end
