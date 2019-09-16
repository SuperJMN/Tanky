using System;
using System.Reactive;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded.Actors
{
    public class Tanky : StageObject
    {
        public enum States
        {
            None,
            Stopped,
            Walking,
            Jumping
        }

        private const int Size = 32;
        private readonly ISubject<Unit> shootAttempt = new Subject<Unit>();
        private readonly ISubject<float> speed = new BehaviorSubject<float>(0F);
        private readonly float baseSpeed = 200F;
        private Texture2D jump;
        private Texture2D walkAnim;
        private SoundEffect jumpSound;
        private SoundEffect shootSound;
        private SoundEffect walkSound;
        private SoundEffectInstance servoSoundInstance;
        private SoundEffect sandSound;

        public Tanky()
        {
            Width = Size;
            Height = Size;
            Top = Constants.GroundTop;

            var distanceAfterLastStop = speed.Scan(0F, (a, b) =>
            {
                if (Sign(a) == Sign(b) || a == 0)
                {
                    return a + b;
                }

                return 0;
            });

            var frameId = distanceAfterLastStop
                .Select(x =>
                {
                    var segment = Math.Abs(x) / 10;
                    return (int)(segment % 8);
                });

            frameId
                .Subscribe(i =>
                {
                    WalkIndex = i;
                });

            shootAttempt
                .ObserveOn(Dispatcher.CurrentDispatcher)
                .Subscribe(_ => Stage.AddRelative(new Shot(), this, RelativePosition.Right));
        }

        public int WalkIndex { get; private set; }

        public States Animation { get; set; }
        public float VerticalSpeed { get; set; }

        private static int Sign(float f)
        {
            if (Math.Abs(f) < 0.5)
            {
                return 0;
            }

            return f > 0 ? 1 : -1;
        }

        public override void LoadContent(ContentManager contentManager)
        {
            walkAnim = contentManager.Load<Texture2D>("Tanky");
            jump = contentManager.Load<Texture2D>("jump");
            jumpSound = contentManager.Load<SoundEffect>("sounds/jump");
            shootSound = contentManager.Load<SoundEffect>("sounds/shoot");
            walkSound = contentManager.Load<SoundEffect>("sounds/servo");
            servoSoundInstance = walkSound.CreateInstance();
            servoSoundInstance.IsLooped = true;
            servoSoundInstance.Volume = 0.5F;
            sandSound = contentManager.Load<SoundEffect>("sounds/sand");
        }

        public override void Update(GameTime gameTime)
        {
            Top += VerticalSpeed * (float)gameTime.ElapsedGameTime.TotalSeconds;
            VerticalSpeed += 30;

            if (Top > Constants.GroundTop)
            {
                VerticalSpeed = 0;
                Top = Constants.GroundTop;
                Land();
            }
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            if (Animation == States.Walking || Animation == States.Stopped)
            {
                var destinationRectangle = new Rectangle((int)Left, (int)Top, (int)Width, (int)Height);
                var sourceRectangle = TextureMixin.GetTile(WalkIndex, 0, Size, Size);
                spriteBatch.Draw(walkAnim, destinationRectangle, sourceRectangle, Color.White);
            }
            else if (Animation == States.Jumping)
            {
                var destinationRectangle = new Rectangle((int)Left, (int)Top, (int)Width, (int)Height);
                var sourceRectangle = new Rectangle(0, 0, Size, Size);
                spriteBatch.Draw(jump, destinationRectangle, sourceRectangle, Color.White);
            }
        }

        public void GoBack(TimeSpan walkingTime)
        {
            if (Animation != States.Jumping)
            {
                Animation = States.Walking;
            }

            var walkFraction = (float)walkingTime.TotalSeconds;
            Left -= baseSpeed * walkFraction;
            speed.OnNext(-(baseSpeed * walkFraction));
        }

        public void Advance(TimeSpan walkingTime)
        {
            if (Animation != States.Jumping)
            {
                Animation = States.Walking;
            }

            var walkFraction = (float)walkingTime.TotalSeconds;

            Left += baseSpeed * walkFraction;
            speed.OnNext(baseSpeed * walkFraction);
        }

        //public void Stop()
        //{
        //    if (Animation != States.Jumping)
        //    {
        //        Animation = States.Stopped;
        //    }

        //    servoSoundInstance.Stop(true);
        //    speed.OnNext(0);
        //}

        public void Jump()
        {
            Animation = States.Jumping;
            jumpSound.Play();
        }

        public void Land()
        {
            Animation = States.Stopped;
        }

        public void Shoot()
        {
            shootAttempt.OnNext(Unit.Default);
            shootSound.Play();
        }
    }
}