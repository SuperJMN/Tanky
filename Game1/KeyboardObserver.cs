using System;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using Microsoft.Xna.Framework.Input;

namespace Tanky
{
    public class KeyboardObserver
    {
        private readonly ISubject<KeyboardState> status = new Subject<KeyboardState>();

        public void Sample()
        {
            status.OnNext(Keyboard.GetState());
        }

        public IObservable<bool> KeyDownChanged(Keys key) => status.Select(x => x.IsKeyDown(key)).DistinctUntilChanged();
        public IObservable<bool> KeyUpChanged(Keys key) => status.Select(x => x.IsKeyDown(key)).DistinctUntilChanged();
    }
}