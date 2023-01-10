# Composable Sensor Reader

This is the [SensorReader](https://www.github.com/tadelv/SensorReader) counterpart, rewritten using [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture).

## Composable Architecture
Composable Architecture is a paradigm published by [PointFree](https://www.pointfree.co). It reminds me of Redux (though I have no experience with it) and was appealing for its extensive support by the authors. The idea of having a state modified by actions sounded very interesting. I took a beginners dive into it, by rewriting SensorReader to be Composable.

## The Process
I planned on reusing the views and the Composition Root, but discarded all business logic. I then built the Readings and Favorites features, each with its own respective state. In a sense, this was already an improvement over the original implementation. The Favorites logic feature is now independent from ReadingsViewModel. 

Another pattern used in the rewrite was Composition. Instead of building a large component juggling multiple responsibiltes, I composed Readings and Favorites features together. Thus ComposedFeature came to be, enabling views to display readings and toggle favorites. In addition,  ComposedFeature also houses logic for setting the server URL. It's the only actual responsibility it has, besides forwarding actions and state to Readings and Favorites. It would be indeed cleaner to use a separate feature, but I'm going to leave that for another time. 

What also changed is the dependency management. Because I ditched the UseCases and moved timer logic into the ReadingsFeature, I was able to simplify dependencies. They became simple structs holding closures, enabling easy overriding in tests. This change also came in handy when changing the server URL.

## Thoughts
Now over the first hurdle, the app is behaving as intended. Even though I developed it with TCA in mind, I'm still a beginner with much to learn. I'm certain I missed a lot of things on which I could improve or choose a different way of implementation altogether.
For now let's just say it was a very interesting journey and I learned something new.