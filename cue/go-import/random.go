package main

import "math/rand"
import "k8s.io/api/core/v1"

func main() {
  for i := 0; i < 10; i++ {
    println(rand.Intn(25))
  }
}
