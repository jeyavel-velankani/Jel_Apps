class MyapisController < ApiController
	def jel_api1
		a = Product.first
		a.suspend!
		render json: {name: 'Jeyavel', action: 'jel_app1'}
	end
end
