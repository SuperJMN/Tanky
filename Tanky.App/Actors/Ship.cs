using System;
using System.Reactive.Linq;
using System.Reactive.Subjects;
using System.Windows.Threading;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame;
using SuperJMN.MonoGame.Common;
using TankyApp.Actors.Shots;

namespace TankyApp.Actors
{
    internal class Ship : StageObject, IDestructable, IDisposable
    {
        private static Texture2D texture;
        private IDisposable bombDropper;
        private readonly ISubject<DefeatedEvent> destroyed = new Subject<DefeatedEvent>();

        public Ship()
        {
            VerticalSpeed = Utils.Random.Next(-120, 100);
            HorizontalSpeed = 200;
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            var sourceRectangle = new Rectangle(0, 0, texture.Width, texture.Height);
            spriteBatch.Draw(texture, Bounds, sourceRectangle, Color.White);
        }

        public override void LoadContent(ContentManager content)
        {
            texture = content.Load<Texture2D>("Ship2");
            this.SetHeight(64, new RectangleAdapter(texture.Bounds));

            bombDropper = ObservableMixin.RandomIntervals(() => TimeSpan.FromMilliseconds(Utils.Random.Next(200, 1800)))
                .ObserveOn(Dispatcher.CurrentDispatcher)
                .Subscribe(_ =>
                {
                    if (Top + Height + 20 < Constants.GroundTop)
                    {
                        var stageObject = new Bomb();
                        stageObject.AlignTo(this, Alignment.ToBottomSide);
                        Stage.Add(stageObject);
                    }
                });
        }

        public override void Initialized()
        {
        }

        public override void Update(GameTime gameTime)
        {
            Left -= gameTime.ElapsedGameTime.TotalSeconds * HorizontalSpeed;
            Top += gameTime.ElapsedGameTime.TotalSeconds * VerticalSpeed;

            if (IsNearVerticalLimits())
            {
                DeccelerateVertically();
            }

            if (this.IsOutOfBounds())
            {
                Dispose();
            }
        }

        private bool IsNearVerticalLimits()
        {
            const int threshold = 50;
            return Bounds.Bottom + threshold >= Constants.GroundTop || Top - threshold <= 0;
        }

        private void DeccelerateVertically()
        {
            VerticalSpeed /= 1.02;
        }

        public override void CollideWith(IStageObject other)
        {
            if (other is Shot s)
            {
                ReceiveDamageFrom(s.Shooter, s.Damage);
            }
        }

        private void ReceiveDamageFrom(IStageObject damager, int damage)
        {
            HitPoints -= damage;
            Left += (float)damage / 3;
            
            if (HitPoints <= 0)
            {
                DestroyBy(damager);
            }
        }

        public int HitPoints { get; set; } = 25;
        public int Damage { get; } = 50;

        private void DestroyBy(IStageObject killer)
        {
            if (IsDestroyed)
            {
                return;
            }

            IsDestroyed = true;

            var aerialExplosion = new AerialExplosion();
            aerialExplosion.AlignTo(this, Alignment.Center);
            Stage.Add(aerialExplosion);
            destroyed.OnNext(new DefeatedEvent(killer, this));
            Dispose();
        }

        public bool IsDestroyed { get; set; }
        
        public void Dispose()
        {
            Stage.Remove(this);
            bombDropper.Dispose();
        }

        public IObservable<DefeatedEvent> Destroyed => destroyed;
    }
}