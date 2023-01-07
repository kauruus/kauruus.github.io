+++
title = "Book Review: Generic Data Structures and Algorithms in Go"
hascode = true
+++

# {{title}}

~~~
<div style="max-width: 250px">
~~~
  ![](/assets/images/bookcover-generic-ds-algo-in-go.jpeg)
~~~
</div>
~~~

I read this book last year, shortly after it's released on O'Reilly. It's probably the worst Go book of 2022.

## A Slow HashTable?

Chapter 7 introduces a simple closed addressing[^1] hash table, and according to author's benchmark, it's **3000x** slower than Go's map[^2].

```
Benchmark test begins to test words: 500000
Time to test all words in myTable: 1m17.880336666s
Time to test words in mapCollection: 24.405583ms

```

> Quite a dramatic difference! -- Dr.Wiener 

How can you accept that you have implemented such a slow hash table without questioning the implementation and benchmark result?

10x is okay since Go's map is highly optimized, but it's 3000x, there must be something wrong.

Let's see if you can spot the problem from only the type definition:

```
const tableSize = 100_000

type HashTable [tableSize]WordType

type WordType struct {
        word string
        list []string
}

func NewTable() HashTable {}

func (table *HashTable) Insert(word string) {}

func (table HashTable) IsPresent(word string) bool {}
```

Aha, `HashTable` is an array, and `IsPresent` takes a value receiver. So everytime you call `IsPresnet`, you make a copy of the array.

I fixed it by simply adding a `*`, and here's the benchmark result:

```
goos: linux
goarch: amd64
cpu: AMD Ryzen 7 5800H with Radeon Graphics
pkg: ...
BenchmarkHashTable-16                 40          25557889 ns/op               0 B/op          0 allocs/op
BenchmarkMap-16                       30          34354666 ns/op               0 B/op          0 allocs/op
PASS
```

In the author's test scenario, the simple hash table is actually faster than Go's map[^3].

The author is just not very rigorous about performance, and probably don't known enough Go :(

## Concurrency?

Besides the introductory chapter, there are only 3 chapters that involve concurrency.

In chapter 4, the book introduces Game of Life. 

It utilize [fyne](https://fyne.io/) to display the grid, so it need to run the simulation in a goroutine. Fair use case but not related to data structure and algorithm.

In chapter 10, it implement a "concurrent" AVL tree, bascailly a sharding map, not very interesting.

In chapter 14, we get another simulation. This time we simulate three species in an ocean.

Inside a 50x50 grid, we have agents that move concurrently according to some rules. Here's how they are implemented:


```
func (shark *Shark) Move() {
	for ; quit == false ; {
		if shark.x == -1 {
			break
		}
		mutex.Lock()
		// ... rules here 
		mutex.Unlock()
		time.Sleep(time.Duration(rand.Intn(500) + 500) * time.Millisecond)
	}
}

func (tuna *Tuna) Move() {
	for ; quit == false ; {
		mutex.Lock()
		// ... rules here 
		mutex.Unlock()
		time.Sleep(time.Duration(rand.Intn(500) + 500) * time.Millisecond)
	}
}

func (mackerel *Mackerel) Move() {
	for ; quit == false ; {
		mutex.Lock()
		// ... rules here 
		mutex.Unlock()
		time.Sleep(time.Duration(rand.Intn(500) + 500) * time.Millisecond)
	}
}

```

So they all take the same mutex, and they can't run concurrency! It's an useless case of goroutine.

Not to mention the data race of the `quit` variable, it needs atomic loading.

And if you run it with `-race`, you can see more data races, lol.

I will simply select one agent randomly and update it, no concurrency, no locking, no data races.

## Waste of paper

Many code are duplicated, first in introduction, then in complete program.

The last chapter include the training progress of a neural networks, 99 lines of `cost = 0.XXXXX`. 

Thank God, the author replace some output with `...`, so we have only 99 lines.

That's probably why this book take 590 pages.

## Generic?

This books actually don't include much generic code.

For introducing generics, I would say most blog post on the internet did a better job than this book.

## Summary 

It's probably the wrost Go book of 2022.

Maybe you would say this is data structures and algorithms book, not a Go book, so some incorrect usage of Go is okay.

But then why not grab a serious algorithm book?

The only possible sell point of this book is Go, but it failed to achieve it.

My rating: ★☆☆☆☆ (1/5), Not Recommended.


[^1]: This book doesn't introduces the concept of open and closed addressing.

[^2]: All benchmark code in this books simply use `time.Now` and `time.Since` to measure the time.

[^3]: I also did this benchmark on my Pentium T4500 machine, still no 10x slowness

```
cpu: Pentium(R) Dual-Core CPU       T4500  @ 2.30GHz
BenchmarkHashTable-2           7         147249004 ns/op               0 B/op          0 allocs/op
BenchmarkMap-2                12          97398657 ns/op               0 B/op          0 allocs/op
```

