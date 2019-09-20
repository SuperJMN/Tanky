using System;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using Microsoft.Xna.Framework.Input;

namespace TankyReloaded
{
    public class KeyboardObserver
    {
        private readonly ISubject<KeyboardState> status = new Subject<KeyboardState>();

        public void Sample()
        {
            status.OnNext(Keyboard.GetState());
        }

        public IObservable<bool> KeyDownChanged(Keys keys) => status.Select(x => x.IsKeyDown(keys)).DistinctUntilChanged();
    }
}