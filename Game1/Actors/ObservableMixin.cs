using System;
using System.Reactive.Concurrency;
using System.Reactive.Linq;

namespace TankyReloaded.Actors
{
    public static class ObservableMixin
    {
        public static IObservable<T> SampleFirst<T>(
            this IObservable<T> source,
            TimeSpan sampleDuration,
            IScheduler scheduler = null)
        {
            scheduler = scheduler ?? Scheduler.Default;
            return source.Publish(ps => 
                ps.Window(() => ps.Delay(sampleDuration,scheduler))
                    .SelectMany(x => x.Take(1)));
        }
    }
}