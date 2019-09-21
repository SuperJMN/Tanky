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
using Tanky.App.Actors.Shots;
using Tanky.App.Actors.Weapons;

namespace Tanky.App.Actors
{
    public class Tanky : StageObject, IDisposable
    {
        private const int Size = 32;
        private const int JumpAcceleration =  800;
        private const float WalkSpeed = 200F;

        private readonly ISubject<Unit> died = new Subject<Unit>();
        private readonly CompositeDisposable disposables = new CompositeDisposable();
        private readonly ISubject<Unit> shootAttempt = new Subject<Unit>();
        private readonly ISubject<float> speed = new BehaviorSubject<float>(0F);

        private Texture2D jump;
        private SoundEffect jumpSound;
        private SoundEffectInstance servoSoundInstance;
        private IDisposable shooter;
        private Texture2D walkAnim;

        private SoundEffect walkSound;
        private SoundEffect dieSound;

        public Tanky()
        {
            Width = Size;
            Height = Size;
            Top = Constants.GroundTop;

            CurrentFrame()
                .Subscribe(i => WalkIndex = i)
                .DisposeWith(disposables);

            IsMovingChanged()
                .Subscribe(isMoving =>
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

        public JumpState JumpState { get; set; }
        private WalkState WalkState { get; set; }

        public int HealthPoints { get; set; } = 10;

        public bool IsVisible { get; set; } = true;

        public LiveStatus LiveStatus { get; set; } = LiveStatus.Alive;

        public int CurrentWeapon { get; set; }
        public IObservable<Unit> Died => died;

        public void Dispose()
        {
            disposables?.Dispose();
        }

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
            dieSound = contentManager.Load<SoundEffect>("sounds/smw_pipe");
            servoSoundInstance = walkSound.CreateInstance();
            servoSoundInstance.IsLooped = true;
            servoSoundInstance.Volume = 0.4F;
        }

        public override void Initialized()
        {
            ChangeWeapon(WeaponInfoFactory.Create(0));
        }

        private void ChangeWeapon(WeaponFactory factory)
        {
            shooter?.Dispose();
            shooter = ShootObservable(factory.ShootingRate)
                .Subscribe(_ => Shoot(factory.CreateShot(this)));
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

        public void HaltJump()
        {
            if (JumpState == JumpState.Jumping && VerticalSpeed < 0)
            {
                VerticalSpeed /= 2;
            }
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            if (!IsVisible)
            {
                return;
            }

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
            Left -= WalkSpeed * walkFraction;
            speed.OnNext(-(WalkSpeed * walkFraction));
        }

        public void Advance(TimeSpan walkingTime)
        {
            var walkFraction = (float) walkingTime.TotalSeconds;
            Left += WalkSpeed * walkFraction;
            speed.OnNext(WalkSpeed * walkFraction);
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
                VerticalSpeed = -JumpAcceleration;
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

        public void SwitchWeapon()
        {
            CurrentWeapon++;
            if (CurrentWeapon == 3)
            {
                CurrentWeapon = 0;
            }

            ChangeWeapon(WeaponInfoFactory.Create(CurrentWeapon));
        }

        public override void CollideWith(IStageObject other)
        {
            if (IsEnemy(other))
            {
                ReceiveDamage(10);
            }
        }

        private static bool IsEnemy(IStageObject other)
        {
            return other is Explosion || other is AerialExplosion || other is Ship;
        }

        private void ReceiveDamage(int damage)
        {
            if (HealthPoints <= 0)
            {
                Die();
            }
            else
            {
                HealthPoints -= damage;
            }
        }

        private void Die()
        {
            if (LiveStatus != LiveStatus.Dead)
            {
                StopRequest();
                dieSound.Play();
                died.OnNext(Unit.Default);
                LiveStatus = LiveStatus.Dead;
            }
        }

        public void Respawn()
        {
            Observable
                .Interval(TimeSpan.FromMilliseconds(50)).Select(l => l % 2 == 0)
                .StartWith(false)
                .Do(isVisible => IsVisible = isVisible)
                .TakeUntil(Observable.Timer(TimeSpan.FromSeconds(3)))
                .Subscribe(_ => { }, () =>
                {
                    IsVisible = true;
                    LiveStatus = LiveStatus.Alive;
                })
                .DisposeWith(disposables);
        }
    }
}