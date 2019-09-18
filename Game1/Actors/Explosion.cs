using System;
using System.Reactive.Linq;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded.Actors
{
    public class Explosion: StageObject, IDisposable
    {
        private AnimatedSprite animation;
        private IDisposable animator;
        private SoundEffect sound;

        public Explosion()
        {
            Width = 80;
            Height = 100;
        }

        public void Dispose()
        {
            animator.Dispose();
            Stage.Remove(this);
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            var location = new Vector2((float) Left, (float) Top);
            animation?.Draw(spriteBatch, location);
        }

        public override void LoadContent(ContentManager content)
        {
            var texture = content.Load<Texture2D>("explosion");
            animation = new AnimatedSprite(texture, 2, 3, (int) Width, (int) Height);
            animator = Observable
                .Interval(TimeSpan.FromMilliseconds(100)).Take(animation.TotalFrames)
                .ObserveOn(Dispatcher.CurrentDispatcher)
                .Subscribe(l => animation.CurrentFrame++, Dispose);
            sound = content.Load<SoundEffect>("sounds/explosion");
        }

        public override void Update(GameTime gameTime)
        {
            if (!IsPlayingSound)
            {
                sound.Play(0.3F, 0, 0);
                IsPlayingSound = true;
            }
        }

        private bool IsPlayingSound { get; set; }
    }
}