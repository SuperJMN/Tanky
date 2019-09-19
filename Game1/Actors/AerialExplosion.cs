using System;
using System.Reactive.Linq;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame;

namespace TankyReloaded.Actors
{
    public class AerialExplosion: StageObject, IDisposable
    {
        private AnimatedSprite animation;
        private IDisposable animator;
        private SoundEffect sound;

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
        public double AnimationTop => Top + (this.Height - animation.Height) / 2;

        public override void LoadContent(ContentManager content)
        {
            var texture = content.Load<Texture2D>("aerial_explosion");
            animation = new AnimatedSprite(texture, 5, 6, 120);
            animator = Observable
                .Interval(TimeSpan.FromMilliseconds(50)).Take(animation.TotalFrames)
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