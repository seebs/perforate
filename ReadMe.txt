This addon is the beginnings of some general-purpose performance hooks.

The exact boundaries of the intended API are a bit fuzzy, but:

	perf.benchmark(expr, count, args)
		Benchmark the evaluation of expr, count times.  If args
		are provided, they are passed as arguments when calling
		expr.  If expr is a function, it is called, if it is a
		string, it is loadstring()d and then called.
	perf.hook(func, timer)
		Creates (if there isn't one) a timer named 'timer' and
		returns a function which will call 'func' and add accumulated
		time to 'timer'.  The function will pass any arguments it
		receives on to func.
	perf.new(timer, started, verbose)
		Creates a new timer if one does not exist, started if
		started.  Emits a message if verbose is true.  Unlike
		other calls, the "already exists" message is NOT displayed
		unless verbose is true, because that would be annoying
		for the internal implicit calls to perf.new.
	perf.elapsed(timer)
		Yields current elapsed time or nil.
	perf.lap(timer)
		Yields current elapsed time or nil, and increments count.
	perf.delete(timer)
		Deletes the specified timer.  If you do this while
		benchmarking using that timer, you will be sad.
	perf.reset(timer, verbose)
		reset a timer, emitting a message if verbose is true
	perf.start(timer, verbose)
	perf.stop(timer, verbose)
	perf.toggle(timer, verbose)
		start, stop, or toggle timer, emitting a message if verbose
		is true.  (Remember, unspecified arguments = nil.)
	perf.showstate(timer)
		Shows the current state of a timer.
	perf.wastetime()
		Make a shallow copy of _G.  This exists just so you can
		see usage examples.

The benchmarking is done in a way intended to minimize disruption, which
is to say, a special hook event is run on every update which evaluates the
given expression (or function) inside a wrapper that runs the corresponding
timer.

Note that "perf." is spelled "Library.LibPerfORate." in code other than
the library source.
