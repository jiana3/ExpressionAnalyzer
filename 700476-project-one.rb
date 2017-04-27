require 'csv'
require 'matrix'

Path = ARGV[0]
Type = ARGV[1]

X = Array.new
Y = Array.new
# CSV.foreach("input_6.txt", :headers => true) do |row|
CSV.foreach(Path, :headers => true) do |row|
X << row[0].to_f
Y << row[1].to_f
end
#Sxx is x1^2 + x2^2 +..+ xn^2; Sx3 is x1^3 + x2^3 +..+ xn^3; Sx4 is x1^4 + x2^4 +..+ xn^4. So does y. 
#Sx2y is x1^2*y + x2^2*y +..+ xn^2*y
N = X.length

Sx = X.reduce(:+)
Sy = Y.reduce(:+)
Sxx = X.map{|l| l**2}.reduce(:+)
Sxy = Matrix.row_vector(X) * Matrix.column_vector(Y)
Syy = Y.map{|l| l**2}.reduce(:+)
Sylnx = Matrix.row_vector(Y)*Matrix.column_vector(X.map{|l| Math.log(l)})
Slnx = X.map{|l| Math.log(l)}.reduce(:+)
Slnx2 = X.map{|l| Math.log(l)**2}.reduce(:+)
Y_ave = Sy/N
Total_var = Y.map{|l| (l - Y_ave)**2}.reduce(:+)
# Sxlny = Matrix.row_vector(X)*Matrix.column_vector(Y.map{|l| Math.log(l)})
# Slny = Y.map{|l| Math.log(l)}.reduce(:+)

def exponential_e
	begin
	Y.map{|l| Math.log(l)}.reduce(:+)
	rescue
	return nil
	end
end

#Linear Regression
#y = b*x + a
def linear
	b = (N*Sxy.element(0,0) - Sx*Sy)/(N*Sxx - Sx**2)
	a = (Sy - b*Sx)/N
	
	y_pre = X.map{|l| b.round(2)*l+a.round(2)}
	explained_var = y_pre.map{|l| (l - Y_ave)**2}.reduce(:+)
	r2 = explained_var/Total_var
	return "#{b.round(2)}x + #{a.round(2)}", r2
end

def r2_fit r2
	fit = r2[0]
	fit_index = 0
	for i in 1..r2.length - 1
		if (r2[i] - 1).abs < (fit - 1).abs
			fit = r2[i]
			fit_index = i
		end
	end
	return fit, fit_index
end

#Polynomial Regression
#y = a0 + a1*x + a2*x^2 +..+ ak*x^k; degree 2 to 10
def poly_regress x, y, degree
	x_degree = x.map{|x_i| (0..degree).map{|l| x_i**l}}
	# Formula of calculate a[k] from https://sph.uth.edu/courses/biometry/Lmoye/PH1820-21/PH1820/lecpoly.htm
	a = (Matrix[*x_degree].transpose*Matrix[*x_degree]).inverse*Matrix[*x_degree].transpose*Matrix.column_vector(y)
	a_round = a.round(2)
	y_pre = Matrix[*x_degree]*Matrix.column_vector(a_round.each().to_a)
	explained_var = y_pre.map{|l| (l - Y_ave)**2}.reduce(:+)
	r2 = explained_var/Total_var
	return a_round, r2
end
def polynomial
	ai = Array.new
	r2 = Array.new
	for i in 1..10
	#get a and r2 of degree 1 to 10
		ai[i-1],r2[i-1] = poly_regress(X,Y,i)
		# puts ai[i-1].inspect, r2[i-1]
	end
	fit_r2,fit_index = r2_fit(r2)
	fit_degree = fit_index + 1
	a_fit = ai[fit_index].each().to_a
	part_equ = Array.new
	for i in 0..fit_degree
		if a_fit[i].round(2) != 0
			if i == 0
				part_equ << "#{a_fit[i].round(2)}"
			elsif i == 1
				part_equ << "#{a_fit[i].round(2)}x"
			else part_equ << "#{a_fit[i].round(2)}x^#{i}"
			end
		end
	end
	equation = "#{part_equ.reverse!.join(" + ")}"
	return equation, fit_r2
end

#Logarithmic Regression
#y = a + b*ln(x)
def logarithmic
	b = (N*Sylnx.element(0,0) - Sy*Slnx)/(N*Slnx2 - Slnx**2)
	a = (Sy - b*Slnx)/N
	y_pre = X.map{|l| a.round(2)+b.round(2)*Math.log(l)}
	explained_var = y_pre.map{|l| (l - Y_ave)**2}.reduce(:+)
	r2 = explained_var/Total_var
	return "#{b.round(2)}*ln(x) + #{a.round(2)}", r2
end

#Exponential Regression
#y=Ae^(Bx)
def exponential
	if exponential_e.nil?
	puts "Cannot perform exponential regression on this data"
	else
	sxlny = Matrix.row_vector(X)*Matrix.column_vector(Y.map{|l| Math.log(l)})
	slny = Y.map{|l| Math.log(l)}.reduce(:+)
	a = (slny*Sxx - Sx*sxlny.element(0,0))/(N*Sxx - Sx**2)
	b = (N*sxlny.element(0,0) - Sx*slny)/(N*Sxx - Sx**2)
	end
	if !a.nil? && !b.nil?
		y_pre = X.map{|l| Math.exp(a.round(2))*(Math.exp(b.round(2))**l)}
		explained_var = y_pre.map{|l| (l - Y_ave)**2}.reduce(:+)
		r2 = explained_var/Total_var
		return "#{Math.exp(a).round(2)}*e^(#{b.round(2)}x)", r2
	else return nil
	end
end

def print_equation type
	if !type.nil?
	puts type[0]
	end
end

def best_fit
	# puts linear
	# puts polynomial
	# puts logarithmic
	# puts exponential
	
	equation = Array.new
	r2 = Array.new

	equation[0],r2[0] = linear
	equation[1],r2[1] = polynomial
	equation[2],r2[2] = logarithmic
	if !exponential_e.nil?
		equation[3],r2[3] = exponential
	end
	fit_r2,fit_index = r2_fit(r2)
	puts equation[fit_index]
end

def do_type type
	if /^linear$/.match(type)
	print_equation(linear)
	end
	if /^polynomial$/.match(type)
	print_equation(polynomial)
	end
	if /^logarithmic$/.match(type)
	print_equation(logarithmic)
	end
	if /^exponential$/.match(type)
	print_equation(exponential)
	end
	if /^best_fit$/.match(type)
	best_fit
	end
end
# best_fit

do_type(Type)