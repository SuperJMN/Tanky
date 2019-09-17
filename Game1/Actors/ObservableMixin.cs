using System;
using System.Reactive;
using System.Reactive.Concurrency;
using System.Reactive.Linq;
using System.Threading.Tasks;

namespace TankyReloaded.Actors
{
    public static class ObservableMixin
    {
        public static IObservable<T> SampleFirst<T>(
            this IObservable<T> source,
            TimeSpan sampleDuration,
            IScheduler scheduler = null)
        {
            scheduler ??= Scheduler.Default;
            return source.Publish(ps => 
                ps.Window(() => ps.Delay(sampleDuration,scheduler))
                    .SelectMany(x => x.Take(1)));
        }

        public static IObservable<Unit> PushRandomly(Func<TimeSpan> intervalSelector)
        {
            return Observable.Create<Unit>(async (obs, ct) =>
            {
                while (!ct.IsCancellationRequested)
                {
                    var randomValue = intervalSelector();
                    await Task.Delay(randomValue, ct);
                    obs.OnNext(Unit.Default);
                }
            });
        }
    }
}