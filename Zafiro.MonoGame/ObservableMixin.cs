using System;
using System.Reactive;
using System.Reactive.Concurrency;
using System.Reactive.Disposables;
using System.Reactive.Linq;
using System.Threading.Tasks;

namespace SuperJMN.MonoGame.Common
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
                ps.Window(() => ps.Delay(sampleDuration, scheduler))
                    .SelectMany(x => x.Take(1)));
        }

        public static IObservable<Unit> RandomIntervals(Func<TimeSpan> nextDelaySelector)
        {
            return Observable.Generate(
                0,
                x => x < 100,
                x => x + 1,
                x => Unit.Default,
                _ => nextDelaySelector());
        }

        public static T DisposeWith<T>(this T disposable, CompositeDisposable compositeDisposable) where T : IDisposable
        {
            compositeDisposable.Add(disposable);
            return disposable;
        }
    }
}