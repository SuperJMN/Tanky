using System;
using System.Reactive.Linq;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame;

namespace Tanky.Actors
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
            var location = new Vector2((float) AnimationLeft, (float) AnimationTop);
            animation?.Draw(spriteBatch, location);
        }

        public double AnimationLeft => Left + (this.Width - animation.Width) / 2;
        public double AnimationTop => Top + this.Height - animation.Height;

        public override void LoadContent(ContentManager content)
        {
            var texture = content.Load<Texture2D>("explosion3");
            animation = new AnimatedSprite(texture, 8, 1, width: 80);
            animator = Observable
                .Interval(TimeSpan.FromMilliseconds(100)).Take(animation.TotalFrames)
                .ObserveOn(Dispatcher.CurrentDispatcher)
                .Subscribe(l => animation.CurrentFrame++, Dispose);
            sound = content.Load<SoundEffect>("sounds/explosion");
        }

        public override void Initialized()
        {
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