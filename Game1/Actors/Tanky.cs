using System;
using System.Reactive;
using System.Reactive.Disposables;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame;
using SuperJMN.MonoGame.Common;

namespace TankyReloaded.Actors
{
    public class Tanky : StageObject, IDisposable
    {
        private const int Size = 32;
        private readonly float baseSpeed = 200F;
        private readonly ISubject<Unit> shootAttempt = new Subject<Unit>();
        private readonly ISubject<float> speed = new BehaviorSubject<float>(0F);
        private Texture2D jump;
        private SoundEffect jumpSound;
        private SoundEffect sandSound;
        private SoundEffectInstance servoSoundInstance;
        private Texture2D walkAnim;

        private SoundEffect walkSound;
        private readonly CompositeDisposable disposables = new CompositeDisposable();
        private IDisposable shooter;

        public Tanky()
        {
            Width = Size;
            Height = Size;
            Top = Constants.GroundTop;

            CurrentFrame()
                .Subscribe(i =>
                {
                    WalkIndex = i;
                    if (i % 4 == 0 && Math.Abs(Top - Constants.GroundTop) < 5)
                    {
                        //sandSound.Play();
                    }
                }).DisposeWith(disposables);

            IsMovingChanged().Subscribe(isMoving =>
            {
                if (isMoving)
                {
                    servoSoundInstance?.Play();
                    WalkState = WalkState.Walking;
                }
                else
                {
                    servoSoundInstance?.Stop(true);
                    WalkState = WalkState.Stopped;
                }
            }).DisposeWith(disposables);
        }

        public int WalkIndex { get; private set; }

        public TankyAnimation Animation { get; set; }

        private JumpState JumpState { get; set; }
        private WalkState WalkState { get; set; }

        private IObservable<bool> IsMovingChanged()
        {
            return speed.Select(s => Math.Abs(s) > 0).DistinctUntilChanged();
        }

        private IObservable<Unit> ShootObservable(TimeSpan timeSpan)
        {
            return shootAttempt
                .SampleFirst(timeSpan)
                .ObserveOn(Dispatcher.CurrentDispatcher);
        }

        private IObservable<int> CurrentFrame()
        {
            var distanceAfterLastStop = speed.Scan(0F, (a, b) =>
            {
                if (Sign(a) == Sign(b) || a == 0)
                {
                    return a + b;
                }

                return 0;
            });

            var frameId = distanceAfterLastStop
                .Where(x => Math.Abs(x) > 0)
                .Select(x =>
                {
                    var segment = Math.Abs(x) / 10;
                    return (int) (segment % 8);
                });
            return frameId;
        }

        private void Shoot(Shot shot)
        {
            shot.AlignTo(this, Alignment.ToRightSide);
            Stage.Add(shot);
        }

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
            walkSound = contentManager.Load<SoundEffect>("sounds/servo");
            servoSoundInstance = walkSound.CreateInstance();
            servoSoundInstance.IsLooped = true;
            servoSoundInstance.Volume = 0.4F;
            sandSound = contentManager.Load<SoundEffect>("sounds/sand");
        }

        public override void Initialized()
        {
            ChangeWeapon(WeaponInfoFactory.Create(0));
        }

        private void ChangeWeapon(WeaponFactory factory)
        {
            shooter?.Dispose();
            shooter = ShootObservable(factory.ShootingRate)
                .Subscribe(_ => Shoot(factory.CreateShot()));
        }

        public override void Update(GameTime gameTime)
        {
            if (this.WillTouchGround(gameTime))
            {
                VerticalSpeed = 0;
                Top = Constants.GroundTop - Height;
                Land();
            }
            else
            {
                VerticalSpeed += Constants.Gravity;
                Top += VerticalSpeed.Apply(gameTime);
            }
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            if (JumpState == JumpState.Jumping)
            {
                Animation = TankyAnimation.Jump;
            }
            else if (WalkState == WalkState.Walking)
            {
                Animation = TankyAnimation.Walking;
            }
            else
            {
                Animation = TankyAnimation.Stopped;
            }

            if (Animation == TankyAnimation.Walking || Animation == TankyAnimation.Stopped)
            {
                var destinationRectangle = new Rectangle((int) Left, (int) Top, (int) Width, (int) Height);
                var sourceRectangle = TextureMixin.GetTile(WalkIndex, 0, Size, Size);
                spriteBatch.Draw(walkAnim, destinationRectangle, sourceRectangle, Color.White);
            }
            else if (Animation == TankyAnimation.Jump)
            {
                var destinationRectangle = new Rectangle((int) Left, (int) Top, (int) Width, (int) Height);
                var sourceRectangle = new Rectangle(0, 0, Size, Size);
                spriteBatch.Draw(jump, destinationRectangle, sourceRectangle, Color.White);
            }
        }

        public void GoBack(TimeSpan walkingTime)
        {
            var walkFraction = (float) walkingTime.TotalSeconds;
            Left -= baseSpeed * walkFraction;
            speed.OnNext(-(baseSpeed * walkFraction));
        }

        public void Advance(TimeSpan walkingTime)
        {
            var walkFraction = (float) walkingTime.TotalSeconds;
            Left += baseSpeed * walkFraction;
            speed.OnNext(baseSpeed * walkFraction);
        }

        public void StopRequest()
        {
            if (WalkState == WalkState.Stopped)
            {
                return;
            }

            Animation = TankyAnimation.Stopped;
            WalkState = WalkState.Stopped;

            speed.OnNext(0);
        }

        public void JumpRequest()
        {
            if (JumpState != JumpState.Jumping)
            {
                JumpState = JumpState.Jumping;
                jumpSound.Play();
                servoSoundInstance.Stop(true);
            }
        }

        private void Land()
        {
            JumpState = JumpState.Landed;
            if (WalkState == WalkState.Walking)
            {
                servoSoundInstance.Play();
            }
        }

        public void ShootRequest()
        {
            shootAttempt.OnNext(Unit.Default);
        }

        public void Dispose()
        {
            disposables?.Dispose();
        }

        public void SwitchWeapon()
        {
            CurrentWeapon++;
            if (CurrentWeapon == 3)
            {
                CurrentWeapon = 0;
            }

            ChangeWeapon(WeaponInfoFactory.Create(CurrentWeapon));
        }

        public int CurrentWeapon { get; set; }
    }
}