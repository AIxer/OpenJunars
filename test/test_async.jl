
func1() = (sleep(2) ; println("test3.jl"))
func2() = (sleep(2) ; println("test_async.jl"))

@async func1()
func2()

sleep